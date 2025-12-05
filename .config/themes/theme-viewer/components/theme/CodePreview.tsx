import { ColorTheme } from './types';

interface CodePreviewProps {
  theme: ColorTheme;
  onColorClick: (category: string, name: string, color: string) => void;
  fontFamily?: string;
}

export function CodePreview({
  theme,
  onColorClick,
  fontFamily = '"BerkeleyMono Nerd Font", "Berkeley Mono", monospace',
}: CodePreviewProps) {
  return (
    <div
      className="p-6 rounded-lg text-sm overflow-x-auto"
      style={{
        backgroundColor: theme.background.primary,
        color: theme.foreground.primary,
        fontFamily,
      }}
    >
      <div className="space-y-1">
        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.comment, fontStyle: "italic" }}
            onClick={() =>
              onColorClick("semantic", "comment", theme.semantic.comment)
            }
          >
            // Calculate the total price of items
          </span>
        </div>

        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            function
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.function }}
            onClick={() =>
              onColorClick("semantic", "function", theme.semantic.function)
            }
          >
            calculateTotal
          </span>
          <span style={{ color: theme.foreground.primary }}>(</span>
          <span style={{ color: theme.foreground.primary }}>items</span>
          <span style={{ color: theme.foreground.primary }}>: </span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.type }}
            onClick={() =>
              onColorClick("semantic", "type", theme.semantic.type)
            }
          >
            Item
          </span>
          <span style={{ color: theme.foreground.primary }}>[]) {"{"}</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            let
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>total</span>
          <span style={{ color: theme.foreground.primary }}>: </span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.type }}
            onClick={() =>
              onColorClick("semantic", "type", theme.semantic.type)
            }
          >
            number
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            =
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.number }}
            onClick={() =>
              onColorClick("semantic", "number", theme.semantic.number)
            }
          >
            0
          </span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            const
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>prefix</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            =
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.string }}
            onClick={() =>
              onColorClick("semantic", "string", theme.semantic.string)
            }
          >
            "Item: "
          </span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            for
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>(</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            const
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>item</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            of
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>items</span>
          <span style={{ color: theme.foreground.primary }}>) {"{"}</span>
        </div>

        <div style={{ paddingLeft: "2rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            if
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>(</span>
          <span style={{ color: theme.foreground.primary }}>item</span>
          <span style={{ color: theme.foreground.primary }}>.</span>
          <span style={{ color: theme.foreground.primary }}>isValid</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            &&
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>item</span>
          <span style={{ color: theme.foreground.primary }}>.</span>
          <span style={{ color: theme.foreground.primary }}>price</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            &gt;
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.number }}
            onClick={() =>
              onColorClick("semantic", "number", theme.semantic.number)
            }
          >
            0
          </span>
          <span style={{ color: theme.foreground.primary }}>) {"{"}</span>
        </div>

        <div style={{ paddingLeft: "3rem" }}>
          <span style={{ color: theme.foreground.primary }}>total</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            +=
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>item</span>
          <span style={{ color: theme.foreground.primary }}>.</span>
          <span style={{ color: theme.foreground.primary }}>price</span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div style={{ paddingLeft: "2rem" }}>
          <span style={{ color: theme.foreground.primary }}>{"}"}</span>
        </div>
        <div style={{ paddingLeft: "1rem" }}>
          <span style={{ color: theme.foreground.primary }}>{"}"}</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            return
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>total</span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div>
          <span style={{ color: theme.foreground.primary }}>{"}"}</span>
        </div>

        <div
          className="mt-4 pt-4 border-t"
          style={{ borderColor: theme.background.overlay }}
        >
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.comment, fontStyle: "italic" }}
            onClick={() =>
              onColorClick("semantic", "comment", theme.semantic.comment)
            }
          >
            // Additional examples
          </span>
        </div>

        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            const
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>isEnabled</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.operator }}
            onClick={() =>
              onColorClick("semantic", "operator", theme.semantic.operator)
            }
          >
            =
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.boolean }}
            onClick={() =>
              onColorClick("semantic", "boolean", theme.semantic.boolean)
            }
          >
            true
          </span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            throw
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            new
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.error }}
            onClick={() =>
              onColorClick("semantic", "error", theme.semantic.error)
            }
          >
            Error
          </span>
          <span style={{ color: theme.foreground.primary }}>(</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.string }}
            onClick={() =>
              onColorClick("semantic", "string", theme.semantic.string)
            }
          >
            "Not implemented"
          </span>
          <span style={{ color: theme.foreground.primary }}>);</span>
        </div>

        <div className="mt-4">
          <span style={{ color: theme.foreground.primary }}>console</span>
          <span style={{ color: theme.foreground.primary }}>.</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.method }}
            onClick={() =>
              onColorClick("semantic", "method", theme.semantic.method)
            }
          >
            log
          </span>
          <span style={{ color: theme.foreground.primary }}>(</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.string }}
            onClick={() =>
              onColorClick("semantic", "string", theme.semantic.string)
            }
          >
            "Success!"
          </span>
          <span style={{ color: theme.foreground.primary }}>);</span>
        </div>

        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            import
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>{"{"} </span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.type }}
            onClick={() =>
              onColorClick("semantic", "type", theme.semantic.type)
            }
          >
            Component
          </span>
          <span style={{ color: theme.foreground.primary }}> {"}"}</span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            from
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.string }}
            onClick={() =>
              onColorClick("semantic", "string", theme.semantic.string)
            }
          >
            "react"
          </span>
          <span style={{ color: theme.foreground.primary }}>;</span>
        </div>

        <div
          className="mt-4 pt-4 border-t"
          style={{ borderColor: theme.background.overlay }}
        >
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.comment, fontStyle: "italic" }}
            onClick={() =>
              onColorClick("semantic", "comment", theme.semantic.comment)
            }
          >
            // React/JSX Example
          </span>
        </div>

        <div>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            function
          </span>{" "}
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.function }}
            onClick={() =>
              onColorClick("semantic", "function", theme.semantic.function)
            }
          >
            Button
          </span>
          <span style={{ color: theme.foreground.primary }}>({"{"}</span>
          <span style={{ color: theme.foreground.primary }}>onClick</span>
          <span style={{ color: theme.foreground.primary }}>, </span>
          <span style={{ color: theme.foreground.primary }}>children</span>
          <span style={{ color: theme.foreground.primary }}>{"}"})</span>
          <span style={{ color: theme.foreground.primary }}> {"{"}</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.keyword }}
            onClick={() =>
              onColorClick("semantic", "keyword", theme.semantic.keyword)
            }
          >
            return
          </span>{" "}
          <span style={{ color: theme.foreground.primary }}>(</span>
        </div>

        <div style={{ paddingLeft: "2rem" }}>
          <span style={{ color: theme.foreground.primary }}>&lt;</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.tag || theme.foreground.primary }}
            onClick={() => {
              if (theme.semantic.tag) {
                onColorClick("semantic", "tag", theme.semantic.tag);
              } else {
                onColorClick("foreground", "primary", theme.foreground.primary);
              }
            }}
          >
            button
          </span>
        </div>
        <div style={{ paddingLeft: "3rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{
              color: theme.semantic.attribute || theme.foreground.primary,
            }}
            onClick={() => {
              if (theme.semantic.attribute) {
                onColorClick("semantic", "attribute", theme.semantic.attribute);
              } else {
                onColorClick("foreground", "primary", theme.foreground.primary);
              }
            }}
          >
            className
          </span>
          <span style={{ color: theme.foreground.primary }}>=</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.string }}
            onClick={() =>
              onColorClick("semantic", "string", theme.semantic.string)
            }
          >
            "px-4 py-2 rounded"
          </span>
        </div>
        <div style={{ paddingLeft: "3rem" }}>
          <span
            className="cursor-pointer hover:underline"
            style={{
              color: theme.semantic.attribute || theme.foreground.primary,
            }}
            onClick={() => {
              if (theme.semantic.attribute) {
                onColorClick("semantic", "attribute", theme.semantic.attribute);
              } else {
                onColorClick("foreground", "primary", theme.foreground.primary);
              }
            }}
          >
            onClick
          </span>
          <span style={{ color: theme.foreground.primary }}>=</span>
          <span style={{ color: theme.foreground.primary }}>
            {"{"}onClick{"}"}
          </span>
        </div>
        <div style={{ paddingLeft: "2rem" }}>
          <span style={{ color: theme.foreground.primary }}>&gt;</span>
        </div>
        <div style={{ paddingLeft: "3rem" }}>
          <span style={{ color: theme.foreground.primary }}>
            {"{"}children{"}"}
          </span>
        </div>
        <div style={{ paddingLeft: "2rem" }}>
          <span style={{ color: theme.foreground.primary }}>&lt;/</span>
          <span
            className="cursor-pointer hover:underline"
            style={{ color: theme.semantic.tag || theme.foreground.primary }}
            onClick={() => {
              if (theme.semantic.tag) {
                onColorClick("semantic", "tag", theme.semantic.tag);
              } else {
                onColorClick("foreground", "primary", theme.foreground.primary);
              }
            }}
          >
            button
          </span>
          <span style={{ color: theme.foreground.primary }}>&gt;</span>
        </div>

        <div style={{ paddingLeft: "1rem" }}>
          <span style={{ color: theme.foreground.primary }}>);</span>
        </div>
        <div>
          <span style={{ color: theme.foreground.primary }}>{"}"}</span>
        </div>
      </div>
    </div>
  );
}