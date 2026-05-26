import { useMemo, useState } from 'react';
import {
  useAplicarOperacaoFinanceiraAdmin,
  useOperacaoFinanceiraAdmin,
  useOperacoesFinanceirasAdmin,
  useResumoOperacaoClienteSafe,
  useResumoOperacaoFinanceiraAdmin,
} from './hooks/useMesaData';
import { canAplicarOperacaoFinanceira } from '../../features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi';

const STATUS_LABELS = {
  simulada: 'Simulada',
  confirmada: 'Confirmada',
  aplicada: 'Aplicada',
  cancelada: 'Cancelada',
  bloqueada: 'Bloqueada',
};

const STATUS_STYLES = {
  simulada: 'bg-[#E6F1FB] text-[#042C53]',
  confirmada: 'bg-[#E1F5EE] text-[#04342C]',
  aplicada: 'bg-[#EEEDFE] text-[#26215C]',
  cancelada: 'bg-[#FDEAEA] text-[#4B1528]',
  bloqueada: 'bg-[#FAEEDA] text-[#412402]',
};

const TIPO_LABELS = {
  antecipacao: 'Antecipação',
  postergacao: 'Postergação',
  vpl: 'VPL',
};

function asArray(payload) {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.operacoes)) return payload.operacoes;
  if (Array.isArray(payload?.data)) return payload.data;
  return [];
}

function pickOperacaoId(operacao) {
  return operacao?.id || operacao?.operacao_id || operacao?.uuid || null;
}

function pickStatus(operacao) {
  return String(operacao?.status_operacao || operacao?.status || 'simulada').toLowerCase();
}

function pickTipo(operacao) {
  return String(operacao?.tipo_operacao || operacao?.tipo || '').toLowerCase();
}

function pickValor(...values) {
  for (const value of values) {
    if (value !== null && value !== undefined && value !== '') return value;
  }
  return null;
}

function fmtBRL(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return '—';
  return parsed.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function fmtData(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.valueOf())) return '—';
  return date.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function safeMessage(error) {
  if (!error) return null;
  if (typeof error === 'string') return error;
  return error.message || 'Não foi possível carregar as informações da operação financeira.';
}

function Section({ title, children, right }) {
  return (
    <section className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] p-3">
      <div className="flex items-start justify-between gap-3 mb-3">
        <h3 className="text-[13px] font-semibold text-[var(--color-text-primary)]">{title}</h3>
        {right}
      </div>
      {children}
    </section>
  );
}

function StatusBadge({ status }) {
  const normalized = String(status || 'simulada').toLowerCase();
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${STATUS_STYLES[normalized] || STATUS_STYLES.simulada}`}>
      {STATUS_LABELS[normalized] || normalized || '—'}
    </span>
  );
}

function InfoGrid({ items }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
      {items.map((item) => (
        <div key={item.label} className="rounded-xl bg-[var(--color-background-secondary)] px-3 py-2">
          <p className="text-[10px] uppercase tracking-wide text-[var(--color-text-tertiary)]">{item.label}</p>
          <p className="text-[13px] font-semibold text-[var(--color-text-primary)] mt-0.5 break-words">{item.value ?? '—'}</p>
        </div>
      ))}
    </div>
  );
}

function OperacaoCard({ operacao, selected, onSelect }) {
  const status = pickStatus(operacao);
  const tipo = pickTipo(operacao);
  const valor = pickValor(
    operacao?.valor_movido,
    operacao?.valor_base,
    operacao?.economia_liquida,
    operacao?.desconto_calculado,
    operacao?.acrescimo_calculado
  );

  return (
    <button
      type="button"
      onClick={onSelect}
      className={`w-full text-left rounded-2xl border p-3 transition-colors ${
        selected
          ? 'border-[var(--color-text-primary)] bg-[var(--color-background-secondary)]'
          : 'border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] hover:border-[var(--color-border-secondary)]'
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[13px] font-semibold text-[var(--color-text-primary)] truncate">
            {TIPO_LABELS[tipo] || tipo || 'Operação financeira'}
          </p>
          <p className="text-[11px] text-[var(--color-text-tertiary)] mt-1">
            Atualizada em {fmtData(operacao?.updated_at || operacao?.created_at)}
          </p>
        </div>
        <StatusBadge status={status} />
      </div>
      <div className="mt-3 flex items-center justify-between gap-3">
        <span className="text-[11px] text-[var(--color-text-secondary)]">Valor de referência</span>
        <span className="text-[13px] font-semibold tabular-nums text-[var(--color-text-primary)]">{fmtBRL(valor)}</span>
      </div>
    </button>
  );
}

function LoadingBox({ label = 'Carregando informações...' }) {
  return (
    <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] p-4 text-center">
      <p className="text-[13px] text-[var(--color-text-secondary)]">loading · {label}</p>
    </div>
  );
}

function ErrorBox({ message, onRetry }) {
  return (
    <div className="rounded-2xl border border-[#F3B8C8] bg-[#FDEAEA] p-4 text-center">
      <p className="text-[13px] font-semibold text-[#4B1528]">erro ao carregar operação financeira</p>
      <p className="text-[12px] text-[#993556] mt-1">{message || 'Tente novamente em instantes.'}</p>
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          className="mt-3 rounded-xl bg-white px-3 py-1.5 text-[12px] font-semibold text-[#4B1528]"
        >
          Tentar novamente
        </button>
      )}
    </div>
  );
}

function EmptyBox() {
  return (
    <div className="rounded-2xl border border-dashed border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] p-6 text-center">
      <div className="text-4xl mb-3">💳</div>
      <p className="text-[14px] font-semibold text-[var(--color-text-primary)]">Nenhuma operação financeira encontrada para esta simulação.</p>
      <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">
        Quando houver antecipação, postergação ou VPL vinculados à proposta, o histórico aparecerá aqui.
      </p>
    </div>
  );
}

function ClienteSafePreview({ resumoClienteSafe, isLoading, error }) {
  if (isLoading) return <LoadingBox label="Carregando prévia cliente-safe..." />;
  if (error) return <ErrorBox message={safeMessage(error)} />;

  const payload = resumoClienteSafe || {};
  const resumo = payload?.resumo_cliente || payload?.resumo || payload;

  return (
    <Section
      title="Prévia cliente-safe"
      right={<span className="rounded-full bg-[#E1F5EE] px-2 py-0.5 text-[11px] font-semibold text-[#04342C]">sem campos internos</span>}
    >
      <InfoGrid
        items={[
          { label: 'Valor apresentado', value: fmtBRL(pickValor(resumo?.valor_apresentado, resumo?.valor_total, resumo?.valor_final)) },
          { label: 'Economia/impacto', value: fmtBRL(pickValor(resumo?.economia, resumo?.impacto_financeiro, resumo?.diferenca)) },
          { label: 'Mensagem', value: resumo?.mensagem || resumo?.descricao || 'Resumo seguro disponível para conferência comercial.' },
          { label: 'Readonly', value: payload?.readonly === true ? 'Sim' : 'Não informado' },
        ]}
      />
    </Section>
  );
}

function AplicarOperacaoModal({ open, applying, observacao, setObservacao, onClose, onConfirm, error }) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-[520px] rounded-2xl bg-[var(--color-background-primary)] p-5 shadow-2xl border border-[var(--color-border-tertiary)]">
        <div className="text-3xl mb-3">⚠️</div>
        <h2 className="text-[16px] font-bold text-[var(--color-text-primary)]">Aplicar operação financeira</h2>
        <p className="text-[13px] leading-relaxed text-[var(--color-text-secondary)] mt-2">
          Você está prestes a aplicar esta operação financeira.
          Essa ação altera o fluxo financeiro da proposta e não deve ser repetida.
          Confirme somente se a operação já foi validada com o cliente e/ou gestor responsável.
        </p>

        <label className="block mt-4">
          <span className="text-[12px] font-semibold text-[var(--color-text-primary)]">Observação opcional</span>
          <textarea
            rows={3}
            value={observacao}
            onChange={(event) => setObservacao(event.target.value)}
            disabled={applying}
            placeholder="Ex.: aplicação confirmada após validação administrativa."
            className="mt-2 w-full resize-none rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-secondary)] p-3 text-[13px] outline-none"
          />
        </label>

        {error && (
          <p className="mt-3 rounded-xl bg-[#FDEAEA] px-3 py-2 text-[12px] text-[#993556]">
            {safeMessage(error)}
          </p>
        )}

        <div className="mt-5 flex gap-2">
          <button
            type="button"
            onClick={onClose}
            disabled={applying}
            className="flex-1 rounded-xl bg-[var(--color-background-secondary)] px-4 py-2 text-[13px] font-semibold text-[var(--color-text-primary)] disabled:opacity-60"
          >
            Cancelar
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={applying}
            className="flex-1 rounded-xl bg-[#04342C] px-4 py-2 text-[13px] font-semibold text-white disabled:opacity-60"
          >
            {applying ? 'Aplicando...' : 'Aplicar operação financeira'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function OperacoesFinanceirasPanel({
  sb,
  token,
  simulacaoId,
  agendaId = null,
  usuarioPodeAplicar = true,
  modo = 'admin',
}) {
  const [statusFiltro, setStatusFiltro] = useState('');
  const [tipoFiltro, setTipoFiltro] = useState('');
  const [selectedOperacaoId, setSelectedOperacaoId] = useState(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [observacao, setObservacao] = useState('');

  const contextoIncompleto = !sb || !token || !simulacaoId;

  const filtros = useMemo(() => ({
    status_operacao: statusFiltro || undefined,
    tipo_operacao: tipoFiltro || undefined,
    limit: 50,
    order_by: 'created_at',
    order_dir: 'desc',
  }), [statusFiltro, tipoFiltro]);

  const operacoesQuery = useOperacoesFinanceirasAdmin({
    sb,
    token,
    simulacaoId,
    agendaId,
    filtros,
  });

  const operacoes = useMemo(() => asArray(operacoesQuery.data), [operacoesQuery.data]);
  const selectedOperacao = useMemo(() => {
    if (!selectedOperacaoId) return null;
    return operacoes.find((item) => pickOperacaoId(item) === selectedOperacaoId) || null;
  }, [operacoes, selectedOperacaoId]);

  const selectedId = selectedOperacaoId || (operacoes.length > 0 ? pickOperacaoId(operacoes[0]) : null);

  const detalheQuery = useOperacaoFinanceiraAdmin({ sb, token, operacaoId: selectedId });
  const resumoAdminQuery = useResumoOperacaoFinanceiraAdmin({ sb, token, operacaoId: selectedId });
  const clienteSafeQuery = useResumoOperacaoClienteSafe({ sb, token, operacaoId: selectedId });
  const aplicarMutation = useAplicarOperacaoFinanceiraAdmin({ sb, token });

  const operacaoBase = detalheQuery.data || selectedOperacao || operacoes[0] || null;
  const gating = canAplicarOperacaoFinanceira({
    operacao: operacaoBase,
    resumoAdmin: resumoAdminQuery.data,
    usuarioPodeAplicar: Boolean(usuarioPodeAplicar && modo === 'admin'),
  });

  const canShowAplicar = modo === 'admin' && gating.allowed === true && Boolean(selectedId);

  const handleSelect = (operacao) => {
    setSelectedOperacaoId(pickOperacaoId(operacao));
    setConfirmOpen(false);
    setObservacao('');
  };

  const handleConfirmAplicar = async () => {
    if (!selectedId || aplicarMutation.isLoading) return;

    await aplicarMutation.mutateAsync({
      operacaoId: selectedId,
      parametros: {
        motivo: 'aplicacao_confirmada_na_interface',
        observacao,
        metadata: {
          origem_componente: 'OperacoesFinanceirasPanel',
        },
      },
    });

    setConfirmOpen(false);
    setObservacao('');
  };

  if (contextoIncompleto) {
    return (
      <div className="rounded-2xl border border-[#FAEEDA] bg-[#FFF8EA] p-4 text-center">
        <p className="text-[14px] font-semibold text-[#412402]">Operações financeiras indisponíveis</p>
        <p className="text-[12px] text-[#6B4E16] mt-1">
          Não foi possível identificar sessão, token ou simulação. A consulta foi bloqueada antes de chamar os hooks de dados.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] p-3">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-[15px] font-bold text-[var(--color-text-primary)]">Operações financeiras</p>
            <p className="text-[12px] text-[var(--color-text-secondary)] mt-1">
              Painel administrativo para leitura, conferência e aplicação controlada de operações confirmadas.
            </p>
          </div>
          <span className="w-fit rounded-full bg-[var(--color-background-secondary)] px-3 py-1 text-[11px] font-semibold text-[var(--color-text-secondary)]">
            modo {modo}
          </span>
        </div>

        <div className="mt-3 flex flex-wrap gap-2">
          <select
            value={statusFiltro}
            onChange={(event) => setStatusFiltro(event.target.value)}
            className="rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] px-3 py-2 text-[12px] outline-none"
          >
            <option value="">Todos os status</option>
            <option value="simulada">Simulada</option>
            <option value="confirmada">Confirmada</option>
            <option value="aplicada">Aplicada</option>
            <option value="cancelada">Cancelada</option>
            <option value="bloqueada">Bloqueada</option>
          </select>

          <select
            value={tipoFiltro}
            onChange={(event) => setTipoFiltro(event.target.value)}
            className="rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] px-3 py-2 text-[12px] outline-none"
          >
            <option value="">Todos os tipos</option>
            <option value="antecipacao">Antecipação</option>
            <option value="postergacao">Postergação</option>
            <option value="vpl">VPL</option>
          </select>

          <button
            type="button"
            onClick={operacoesQuery.reload}
            disabled={operacoesQuery.isLoading}
            className="rounded-xl bg-[var(--color-background-secondary)] px-3 py-2 text-[12px] font-semibold text-[var(--color-text-primary)] disabled:opacity-60"
          >
            Atualizar
          </button>
        </div>
      </div>

      {operacoesQuery.isLoading && <LoadingBox label="Carregando operações financeiras..." />}
      {operacoesQuery.error && <ErrorBox message={operacoesQuery.error} onRetry={operacoesQuery.reload} />}
      {!operacoesQuery.isLoading && !operacoesQuery.error && operacoes.length === 0 && <EmptyBox />}

      {!operacoesQuery.isLoading && !operacoesQuery.error && operacoes.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-[360px_1fr] gap-3">
          <div className="space-y-2">
            <p className="text-[11px] uppercase tracking-wide font-semibold text-[var(--color-text-tertiary)]">
              {operacoes.length} operação(ões)
            </p>
            {operacoes.map((operacao) => {
              const id = pickOperacaoId(operacao);
              const selected = id === selectedId;
              return (
                <OperacaoCard
                  key={id || JSON.stringify(operacao).slice(0, 80)}
                  operacao={operacao}
                  selected={selected}
                  onSelect={() => handleSelect(operacao)}
                />
              );
            })}
          </div>

          <div className="space-y-3">
            {detalheQuery.isLoading && <LoadingBox label="Carregando detalhe administrativo..." />}
            {detalheQuery.error && <ErrorBox message={detalheQuery.error} onRetry={detalheQuery.reload} />}

            {!detalheQuery.isLoading && !detalheQuery.error && operacaoBase && (
              <Section title="Detalhe administrativo" right={<StatusBadge status={pickStatus(operacaoBase)} />}>
                <InfoGrid
                  items={[
                    { label: 'Tipo', value: TIPO_LABELS[pickTipo(operacaoBase)] || pickTipo(operacaoBase) || '—' },
                    { label: 'Status', value: STATUS_LABELS[pickStatus(operacaoBase)] || pickStatus(operacaoBase) },
                    { label: 'Valor movido', value: fmtBRL(operacaoBase?.valor_movido) },
                    { label: 'Valor base', value: fmtBRL(operacaoBase?.valor_base) },
                    { label: 'Economia líquida', value: fmtBRL(operacaoBase?.economia_liquida) },
                    { label: 'Atualizado em', value: fmtData(operacaoBase?.updated_at || operacaoBase?.created_at) },
                  ]}
                />
              </Section>
            )}

            {resumoAdminQuery.isLoading && <LoadingBox label="Carregando resumo administrativo..." />}
            {resumoAdminQuery.error && <ErrorBox message={resumoAdminQuery.error} onRetry={resumoAdminQuery.reload} />}

            {!resumoAdminQuery.isLoading && !resumoAdminQuery.error && resumoAdminQuery.data && (
              <Section
                title="Resumo administrativo"
                right={<span className="rounded-full bg-[var(--color-background-secondary)] px-2 py-0.5 text-[11px] font-semibold text-[var(--color-text-secondary)]">readonly</span>}
              >
                <InfoGrid
                  items={[
                    { label: 'Readonly', value: resumoAdminQuery.data?.readonly === true ? 'Sim' : 'Não informado' },
                    { label: 'Cliente safe', value: resumoAdminQuery.data?.cliente_safe === true ? 'Sim' : 'Não informado' },
                    { label: 'Checksum', value: resumoAdminQuery.data?.checksum_operacao || resumoAdminQuery.data?.checksum || '—' },
                    { label: 'Status consolidado', value: STATUS_LABELS[pickStatus(resumoAdminQuery.data?.operacao || resumoAdminQuery.data)] || pickStatus(resumoAdminQuery.data?.operacao || resumoAdminQuery.data) },
                  ]}
                />
              </Section>
            )}

            <ClienteSafePreview
              resumoClienteSafe={clienteSafeQuery.data}
              isLoading={clienteSafeQuery.isLoading}
              error={clienteSafeQuery.error}
            />

            <Section title="Ação administrativa">
              <div className="rounded-xl bg-[var(--color-background-secondary)] p-3">
                {canShowAplicar ? (
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <p className="text-[13px] font-semibold text-[var(--color-text-primary)]">Aplicação liberada pelo guard visual</p>
                      <p className="text-[12px] text-[var(--color-text-secondary)] mt-1">
                        A RPC continuará sendo a autoridade final antes de alterar qualquer fluxo financeiro.
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setConfirmOpen(true)}
                      disabled={aplicarMutation.isLoading}
                      className="rounded-xl bg-[#04342C] px-4 py-2 text-[13px] font-semibold text-white disabled:opacity-60"
                    >
                      Aplicar operação financeira
                    </button>
                  </div>
                ) : (
                  <div>
                    <p className="text-[13px] font-semibold text-[var(--color-text-primary)]">Aplicação bloqueada</p>
                    <p className="text-[12px] text-[var(--color-text-secondary)] mt-1">
                      Motivo: {gating.reason || 'operação sem condição de aplicação no momento'}.
                    </p>
                  </div>
                )}
              </div>
            </Section>
          </div>
        </div>
      )}

      <AplicarOperacaoModal
        open={confirmOpen}
        applying={aplicarMutation.isLoading}
        observacao={observacao}
        setObservacao={setObservacao}
        onClose={() => !aplicarMutation.isLoading && setConfirmOpen(false)}
        onConfirm={handleConfirmAplicar}
        error={aplicarMutation.mappedError?.message || aplicarMutation.error}
      />
    </div>
  );
}
