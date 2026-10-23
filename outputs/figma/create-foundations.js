/**
 * createVariableCollection
 *
 * Creates a new Figma variable collection with the specified name and modes.
 * If `modeNames` has more than one entry, the first mode is renamed from
 * Figma's default "Mode 1" to the first name, and additional modes are added.
 *
 * @param {string} name - The display name of the collection (e.g. "Color", "Spacing").
 * @param {string[]} modeNames - Ordered list of mode names (e.g. ["Light", "Dark"] or ["Value"]).
 * @returns {Promise<{
 *   collection: VariableCollection,
 *   modeIds: Record<string, string>
 * }>}
 *   `modeIds` maps each mode name to its modeId string.
 */
async function createVariableCollection(name, modeNames) {
  if (!modeNames || modeNames.length === 0) {
    throw new Error('createVariableCollection: modeNames must have at least one entry.')
  }

  // Create the collection — Figma always creates it with one mode named "Mode 1".
  const collection = figma.variables.createVariableCollection(name)

  // modeIds accumulator
  const modeIds = {}

  // Rename the default first mode
  const defaultMode = collection.modes[0]
  collection.renameMode(defaultMode.modeId, modeNames[0])
  modeIds[modeNames[0]] = defaultMode.modeId

  // Add additional modes
  for (let i = 1; i < modeNames.length; i++) {
    const newModeId = collection.addMode(modeNames[i])
    modeIds[modeNames[i]] = newModeId
  }

  return { collection, modeIds }
}

/**
 * createSemanticTokens
 *
 * Creates a batch of Figma variables in the given collection, one per entry in
 * `tokenMap`. Supports raw values, variable alias references, code syntax, and
 * scopes. Returns a map of token name → Variable for use in subsequent steps.
 *
 * @param {VariableCollection} collection - The target variable collection.
 * @param {Record<string, string>} modeIds - Map of {modeName: modeId} from createVariableCollection.
 * @param {Array<{
 *   name: string,
 *   type: 'COLOR' | 'FLOAT' | 'STRING' | 'BOOLEAN' | 'TIMING' | 'EASING',
 *   values: Record<string, string | number | boolean | MotionEasing | {type: 'VARIABLE_ALIAS', id: string}>,
 *   scopes?: VariableScope[],
 *   codeSyntax?: {WEB?: string, ANDROID?: string, iOS?: string}
 * }>} tokenMap - Ordered list of token definitions.
 *   - `name`: Variable name using slash hierarchy (e.g. "color/bg/primary").
 *   - `type`: Figma variable type.
 *   - `values`: Map of {modeName: value}. Values can be raw (hex string for COLOR,
 *     number for FLOAT) or alias objects {type: 'VARIABLE_ALIAS', id: variableId}.
 *     For COLOR, raw values are accepted as hex strings ("#rrggbb" or "#rrggbbaa")
 *     and converted to {r, g, b, a} automatically.
 *   - `scopes`: Array of VariableScope strings. Omit to use [] (hidden/primitive).
 *   - `codeSyntax`: Platform code syntax strings. Omit to skip.
 * @returns {Promise<{variables: Record<string, Variable>}>}
 *   `variables` maps each token name to its created Variable object.
 */
async function createSemanticTokens(collection, modeIds, tokenMap) {
  const variables = {}

  for (const token of tokenMap) {
    // Create the variable
    const variable = figma.variables.createVariable(token.name, collection, token.type)

    // Set values for each mode
    for (const [modeName, rawValue] of Object.entries(token.values)) {
      const modeId = modeIds[modeName]
      if (!modeId) {
        throw new Error(
          `createSemanticTokens: mode "${modeName}" not found in modeIds for token "${token.name}". ` +
            `Available modes: ${Object.keys(modeIds).join(', ')}`,
        )
      }

      let value = rawValue

      // Convert hex strings to Figma RGBA for COLOR type
      if (token.type === 'COLOR' && typeof rawValue === 'string' && rawValue.startsWith('#')) {
        value = hexToFigmaColor(rawValue)
      }

      variable.setValueForMode(modeId, value)
    }

    // Set scopes (default: empty array = hidden from property pickers / primitives)
    variable.scopes = token.scopes || []

    // Set code syntax per platform
    if (token.codeSyntax) {
      if (token.codeSyntax.WEB) {
        variable.setVariableCodeSyntax('WEB', token.codeSyntax.WEB)
      }
      if (token.codeSyntax.ANDROID) {
        variable.setVariableCodeSyntax('ANDROID', token.codeSyntax.ANDROID)
      }
      if (token.codeSyntax.iOS) {
        variable.setVariableCodeSyntax('iOS', token.codeSyntax.iOS)
      }
    }

    variables[token.name] = variable
  }

  return { variables }
}

/**
 * Converts a hex color string to a Figma RGBA object.
 * Supports "#rgb", "#rrggbb", and "#rrggbbaa".
 *
 * @param {string} hex
 * @returns {{ r: number, g: number, b: number, a: number }}
 */
function hexToFigmaColor(hex) {
  let h = hex.replace('#', '')

  // Expand shorthand #rgb → #rrggbb
  if (h.length === 3) {
    h = h
      .split('')
      .map((c) => c + c)
      .join('')
  }

  const r = parseInt(h.substring(0, 2), 16) / 255
  const g = parseInt(h.substring(2, 4), 16) / 255
  const b = parseInt(h.substring(4, 6), 16) / 255
  const a = h.length === 8 ? parseInt(h.substring(6, 8), 16) / 255 : 1

  return { r, g, b, a }
}

const data={"name": "mac-setup", "sourceOfTruth": ["docs/assets/style.css", "docs/assets/liquid.css"], "repository": "https://github.com/pedrobritx/mac-setup", "modes": {"dark": {"bg": "#10131a", "window": "rgb(17 24 37 / 84%)", "popover": "rgb(21 30 45 / 96%)", "surface": "rgb(28 39 57 / 76%)", "surface-soft": "rgb(151 184 226 / 5%)", "field": "rgb(9 17 30 / 46%)", "ink": "#edf2fc", "muted": "#b1bfd4", "quiet": "#9aacc5", "border": "rgb(183 212 250 / 16%)", "control-border": "#72849f", "accent": "#9aeadb", "accent-hover": "#c3fff2", "tint": "rgb(115 211 219 / 13%)", "green": "#9de8be", "warn": "#f6d49d", "warn-bg": "#302b26", "mint": "#7ee8c7", "sky": "#7fb5ff", "lilac": "#c5a6ff", "title-gradient": "linear-gradient(115deg, #95efce, #91c5ff 49%, #c5a6ff)", "accent-gradient": "linear-gradient(110deg, #9ef3db, #94caff 56%, #c9b1ff)", "rim": "rgb(206 230 255 / 28%)", "sheen": "rgb(211 238 255 / 12%)", "shadow": "0 18px 54px rgb(2 7 17 / 26%)", "radius": "22px", "ambient-opacity": "0.75"}, "light": {"bg": "#edf1f8", "window": "rgb(246 249 255 / 87%)", "popover": "rgb(252 254 255 / 96%)", "surface": "rgb(255 255 255 / 78%)", "surface-soft": "rgb(75 114 174 / 5%)", "field": "rgb(244 248 255 / 80%)", "ink": "#202e43", "muted": "#4e607b", "quiet": "#596d89", "border": "rgb(65 94 138 / 18%)", "control-border": "#6f8098", "accent": "#206477", "accent-hover": "#144658", "tint": "rgb(89 163 204 / 12%)", "green": "#286540", "warn": "#765018", "warn-bg": "#fff5df", "mint": "#7ee8c7", "sky": "#7fb5ff", "lilac": "#c5a6ff", "title-gradient": "linear-gradient(115deg, #16795f, #255cc0 49%, #703db7)", "accent-gradient": "linear-gradient(110deg, #9ef3db, #94caff 56%, #c9b1ff)", "rim": "rgb(255 255 255 / 90%)", "sheen": "rgb(255 255 255 / 70%)", "shadow": "0 18px 54px rgb(42 68 109 / 13%)", "radius": "22px", "ambient-opacity": "0.15"}}, "motion": {"duration-quick": "150ms", "duration-fast": "250ms", "duration-slow": "400ms", "ease-smooth-out": "cubic-bezier(0.22, 1, 0.36, 1)", "ease-liquid": "cubic-bezier(0.2, 1.45, 0.4, 1)", "modal-open-dur": "250ms", "modal-close-dur": "150ms", "modal-scale": "0.96", "modal-scale-close": "0.96", "modal-ease": "cubic-bezier(0.22, 1, 0.36, 1)", "check-box": "150ms", "check-draw": "350ms", "check-uncheck": "150ms", "check-ease": "cubic-bezier(0.22, 1, 0.36, 1)", "liquid-opacity": "0.3"}, "notes": ["Current implementation values; consistency-review proposals are not implemented.", "System font stack retained in code; Figma font availability must be verified."]};
const page=await figma.getNodeByIdAsync('0:1'); await figma.setCurrentPageAsync(page);
const existing=await figma.variables.getLocalVariableCollectionsAsync();
if(existing.some(c=>c.name==='mac-setup / Appearance')) throw new Error('Foundations already exist; inspect ledger before rerun.');
const primitive=await createVariableCollection('mac-setup / Primitives',['Value']);
const appearance=await createVariableCollection('mac-setup / Appearance',['Dark','Light']);
const geometry=await createVariableCollection('mac-setup / Geometry',['Value']);
const motion=await createVariableCollection('mac-setup / Motion',['Value']);
function colour(s){if(s.startsWith('#')) return hexToFigmaColor(s);const n=s.match(/[\d.]+/g).map(Number);return {r:n[0]/255,g:n[1]/255,b:n[2]/255,a:n.length>3?n[3]/100:1};}
const tokens=[],primitiveMap=[],geometryMap=[],motionMap=[];
for(const [key,value] of Object.entries(data.modes.dark)){
const isColour=value.startsWith('#')||value.startsWith('rgb(');
let values={};
if(isColour){for(const mode of ['Dark','Light']) {const name=mode.toLowerCase()+'/'+key;primitiveMap.push({name,type:'COLOR',values:{Value:colour(data.modes[mode.toLowerCase()][key])},scopes:[],codeSyntax:{WEB:'var(--'+key+')'}});}}
else values={Dark:key==='radius'?22:key==='ambient-opacity'?0.75:value,Light:key==='radius'?22:key==='ambient-opacity'?0.15:data.modes.light[key]};
tokens.push({name:key,type:isColour?'COLOR':key==='radius'||key==='ambient-opacity'?'FLOAT':'STRING',values,scopes:isColour?(['ink','muted','quiet'].includes(key)?['TEXT_FILL']:key.includes('border')||key==='rim'?['STROKE_COLOR']:['FRAME_FILL','SHAPE_FILL']):key==='radius'?['CORNER_RADIUS']:[],codeSyntax:{WEB:'var(--'+key+')'}});
}
const primitives=(await createSemanticTokens(primitive.collection,primitive.modeIds,primitiveMap)).variables;
for(const token of tokens)if(token.type==='COLOR')token.values={Dark:{type:'VARIABLE_ALIAS',id:primitives['dark/'+token.name].id},Light:{type:'VARIABLE_ALIAS',id:primitives['light/'+token.name].id}};
const semantic=(await createSemanticTokens(appearance.collection,appearance.modeIds,tokens)).variables;
for(const n of [4,6,8,10,12,13,14,15,16,18,20,22,23,24,28,32,36,40,44,46,48]){
geometryMap.push({name:'space/'+n,type:'FLOAT',values:{Value:n},scopes:['GAP'],codeSyntax:{WEB:n+'px'}});
if([6,8,10,13,16,18,20,22,23,24,28,40].includes(n))geometryMap.push({name:'radius/'+n,type:'FLOAT',values:{Value:n},scopes:['CORNER_RADIUS'],codeSyntax:{WEB:n+'px'}});
}
for(const [key,value]of Object.entries(data.motion))motionMap.push({name:key,type:'STRING',values:{Value:value},scopes:[],codeSyntax:{WEB:'var(--'+key+')'}});
const dimensions=(await createSemanticTokens(geometry.collection,geometry.modeIds,geometryMap)).variables;
const motions=(await createSemanticTokens(motion.collection,motion.modeIds,motionMap)).variables;
await Promise.all(['Regular','Medium','Semibold','Bold'].map(style=>figma.loadFontAsync({family:'SF Pro',style})));
const styles=[];
for(const [name,size,style]of [['Display',60,'Bold'],['Section',22,'Bold'],['Control',13,'Semibold'],['Body',14,'Regular'],['Caption',11,'Regular']]){const t=figma.createTextStyle();t.name='mac-setup / '+name;t.fontName={family:'SF Pro',style};t.fontSize=size;t.lineHeight={unit:'PERCENT',value:150};styles.push(t.id);}
const pages={};for(const name of ['00 · Start here','01 · Foundations','02 · Components','03 · Screens']){const p=figma.createPage();p.name=name;pages[name]=p.id;}
return {createdNodeIds:Object.values(pages),collections:[primitive,appearance,geometry,motion].map(x=>({id:x.collection.id,name:x.collection.name,modes:x.modeIds})),variables:Object.fromEntries([...Object.entries(semantic),...Object.entries(dimensions),...Object.entries(motions)].map(([k,v])=>[k,v.id])),primitiveCount:Object.keys(primitives).length,styleIds:styles,pages};