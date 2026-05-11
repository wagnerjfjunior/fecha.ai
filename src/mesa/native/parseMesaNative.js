import { detectLayout } from "../layoutDetector";
import { parseSplitBlockTable } from "../parsers/parseSplitBlockTable";

export function parseMesaNative(text, options = {}) {
  const detection = detectLayout(text);

  switch (detection.layout) {
    case "split_block_table": {
      const result = parseSplitBlockTable(text, options);
      return {
        ...result,
        detection: {
          ...detection,
          native: true,
        },
      };
    }

    default:
      return {
        rows: [],
        csvText: "",
        detection,
        diagnostics: {
          parser: "parseMesaNative",
          native: false,
          reason: "layout_not_supported_by_native_parser_yet",
        },
      };
  }
}

export function canUseNativeMesaParser(text) {
  const detection = detectLayout(text);
  return detection.layout === "split_block_table";
}
