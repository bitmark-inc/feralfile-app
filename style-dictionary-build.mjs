import StyleDictionary from "style-dictionary";
import { register } from "@tokens-studio/sd-transforms";
import { expandTypesMap } from "@tokens-studio/sd-transforms";

register(StyleDictionary, {
  excludeParentKeys: true,
  withSDBuiltins: true,
  "ts/color/modifiers": {
    format: "hex",
  },
});

StyleDictionary.registerTransform({
  name: `dart/size/number`,
  type: `value`,
  transitive: true,
  filter: (token) => {
    return (
      [
        "fontSize",
        "dimension",
        "border",
        "typography",
        "shadow",
        "letterSpacing",
      ].includes(token.$type) &&
      (token.$value.endsWith("px") || token.$value.endsWith("em"))
    );
  },
  transform: (token) => {
    return Number(token.$value.replace(/px|em/g, ""));
  },
});

StyleDictionary.registerTransform({
  name: `dart/none/null`,
  type: `value`,
  transitive: true,
  filter: (token) => {
    return token.$value === "none";
  },
  transform: (token) => {
    return null;
  },
});

const sd = new StyleDictionary({
  source: ["design/app.tokens.json"],
  preprocessors: ["tokens-studio"],
  platforms: {
    flutter: {
      buildPath: "design/",
      files: [
        {
          destination: "tokens.dart",
          format: "flutter/class.dart",
          options: {
            className: "Tokens",
          },
        },
      ],
      transformGroup: "tokens-studio",
      transforms: [
        "attribute/cti",
        "color/hex8flutter",
        "content/flutter/literal",
        "asset/flutter/literal",
        "dart/size/number",
        "dart/none/null",
      ],
    },
  },
  expand: {
    typesMap: expandTypesMap,
  },
});
await sd.cleanAllPlatforms();
await sd.buildAllPlatforms();
