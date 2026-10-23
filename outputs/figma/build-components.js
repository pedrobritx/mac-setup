// Editable source-derived components. Capture fonts missing on the server use Cousine.
const sourcePage=await figma.getNodeByIdAsync('0:1');
await figma.setCurrentPageAsync(sourcePage);
const target=await figma.getNodeByIdAsync('4:132');
const root=await figma.getNodeByIdAsync('2:2');
const created=[],mutated=[],mapping={};
const fonts=new Map();
for(const id of ['2:2','5:2','12:2','10:2','11:2']){
 const n=await figma.getNodeByIdAsync(id);
 for(const t of n.findAllWithCriteria({types:['TEXT']}))for(const seg of t.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(seg.fontName),seg.fontName);
}
await figma.loadFontAsync({family:'Cousine',style:'Regular'});
for(const f of fonts.values())if(f.family!=='Menlo')await figma.loadFontAsync(f);
for(const id of ['2:2','5:2','12:2','10:2','11:2']){
 const n=await figma.getNodeByIdAsync(id);
 for(const t of n.findAllWithCriteria({types:['TEXT']}))if(t.fontName!==figma.mixed&&t.fontName.family==='Menlo'){t.fontName={family:'Cousine',style:'Regular'};mutated.push(t.id);}
}
const allVariables=await figma.variables.getLocalVariablesAsync();
const semantic=allVariables.filter(v=>v.variableCollectionId==='VariableCollectionId:4:3');
const primitive=allVariables.filter(v=>v.variableCollectionId==='VariableCollectionId:4:2');
const geom=allVariables.filter(v=>v.variableCollectionId==='VariableCollectionId:4:4');
const mode='4:1';
function colour(v){const x=v.valuesByMode[mode];if(x?.type==='VARIABLE_ALIAS')return primitive.find(p=>p.id===x.id)?.valuesByMode['4:0'];return x;}
function bind(n){
 if('fills'in n && n.fills!==figma.mixed)n.fills=n.fills.map(p=>{
  if(p.type!=='SOLID')return p;
  const v=semantic.find(v=>v.resolvedType==='COLOR'&&(()=>{const c=colour(v);return c&&Math.abs(c.r-p.color.r)<.003&&Math.abs(c.g-p.color.g)<.003&&Math.abs(c.b-p.color.b)<.003&&Math.abs(c.a-(p.opacity??1))<.012;})());
  return v?figma.variables.setBoundVariableForPaint(p,'color',v):p;
 });
 if('cornerRadius'in n&&typeof n.cornerRadius==='number'){
  const v=geom.find(v=>v.name==='radius/'+n.cornerRadius);if(v)n.setBoundVariable('cornerRadius',v);
 }
 if('layoutMode'in n&&n.layoutMode!=='NONE')for(const field of ['paddingTop','paddingBottom','paddingLeft','paddingRight','itemSpacing']){
  const v=geom.find(v=>v.name==='space/'+n[field]);if(v)n.setBoundVariable(field,v);
 }
 if('children'in n)for(const c of n.children)bind(c);
}
function family(name,entries,x,y){
 const comps=[];
 for(const [sourceId,state]of entries){const src=root.findOne(n=>n.id===sourceId);if(!src)throw Error('Missing source '+sourceId);const clone=src.clone();target.appendChild(clone);const c=figma.createComponentFromNode(clone);created.push(c.id,...c.findAll(()=>true).map(n=>n.id));c.name='State='+state;c.description='Approved implementation: '+name+'. Source: https://github.com/pedrobritx/mac-setup/blob/codex/mac-setup-browser-design/docs/assets/style.css';bind(c);comps.push(c);mapping[sourceId]=c.id;}
 const set=figma.combineAsVariants(comps,target);created.push(set.id);set.name='mac-setup / '+name;set.description='Source-derived states. Browser spring and pointer effects are implemented in docs/assets/liquid.mjs and liquid.css.';set.x=x;set.y=y;
 let pos=24;for(const c of set.children){c.x=pos;c.y=32;pos+=c.width+24;}set.resize(pos,Math.max(...comps.map(c=>c.height))+64);return set.id;
}
const sets={};
sets.Primary=family('Button / Primary',[['2:1293','Resting']],160,160);
sets.Secondary=family('Button / Secondary',[['2:248','Resting']],160,330);
sets.Tertiary=family('Button / Tertiary',[['2:221','Resting']],160,500);
sets.Icon=family('Button / Icon',[['2:34','Resting']],160,670);
sets.Profile=family('Profile card',[['2:111','Resting'],['2:99','Selected']],160,840);
sets.Category=family('Category',[['2:172','Resting'],['2:167','Selected']],160,1060);
sets.AppRow=family('Catalogue row',[['2:264','Resting']],160,1230);
sets.Checkbox=family('Checkbox',[['2:266','Unchecked']],160,1420);
return {createdNodeIds:created,mutatedNodeIds:mutated,mapping,sets,componentCount:Object.keys(mapping).length,fontFallback:'Cousine Regular replaces unavailable Menlo only'};
