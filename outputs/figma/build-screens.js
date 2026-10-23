const sources=[];for(const id of ['2:2','5:2','12:2','10:2','11:2'])sources.push(await figma.getNodeByIdAsync(id));
const fonts=new Map();for(const src of sources)for(const t of src.findAllWithCriteria({types:['TEXT']}))for(const seg of t.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(seg.fontName),seg.fontName);
for(const f of fonts.values())if(f.family!=='Menlo')await figma.loadFontAsync(f);
await figma.loadFontAsync({family:'Cousine',style:'Regular'});
for(const src of sources)for(const t of src.findAllWithCriteria({types:['TEXT']}))for(const seg of t.getStyledTextSegments(['fontName']))if(seg.fontName.family==='Menlo')t.setRangeFontName(seg.start,seg.end,{family:'Cousine',style:'Regular'});
const page=await figma.getNodeByIdAsync('4:133');await figma.setCurrentPageAsync(page);
const created=[],mutated=[];
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

const mapping={'2:1293':'15:8','2:248':'15:15','2:221':'15:19','2:34':'15:25','2:111':'15:34','2:99':'15:43','2:172':'15:50','2:167':'15:56','2:264':'15:72'};
function path(root,n){const parts=[];while(n!==root){parts.unshift(n.parent.children.indexOf(n));n=n.parent;}return parts;}
const first=sources[0];const paths=[];for(const [id,component]of Object.entries(mapping)){const n=first.findOne(n=>n.id===id);paths.push({path:path(first,n),component});}
const screens=[];
for(let i=0;i<sources.length;i++){
 const src=sources[i],clone=src.clone();page.appendChild(clone);clone.name=['01 · Choose & customise / Desktop','05 · Safety & privacy','02 · Review setup','03 · Guided handoff','04 · Installation progress / Design specimen'][i];clone.x=160+i*1440;clone.y=160;
 if(i===0){const replacements=paths.map(entry=>({...entry,node:entry.path.reduce((n,k)=>n.children[k],clone)}));for(const item of replacements){const old=item.node;const parent=old.parent,index=parent.children.indexOf(old);const c=await figma.getNodeByIdAsync(item.component);const inst=c.createInstance();parent.insertChild(index,inst);inst.x=old.x;inst.y=old.y;inst.resize(old.width,old.height);inst.name=c.parent.name;old.remove();}}
 bind(clone);created.push(clone.id,...clone.findAll(()=>true).map(n=>n.id));screens.push({id:clone.id,name:clone.name,width:clone.width,height:clone.height,editableText:clone.findAllWithCriteria({types:['TEXT']}).length,instances:clone.findAllWithCriteria({types:['INSTANCE']}).length});
}
return {createdNodeIds:created,mutatedNodeIds:mutated,screens};
