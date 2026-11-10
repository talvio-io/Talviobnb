const fs = require('fs');
const path = require('path');
const solc = require('/home/hatch/workspace/tools/solc0820/node_modules/solc');
const dir = '/home/hatch/workspace/tools/solc0820';
const sources = { 'TalvioToken.sol': { content: fs.readFileSync(path.join(__dirname, 'TalvioToken.sol'), 'utf8') } };
const input = { language: 'Solidity', sources, settings: { optimizer: { enabled: true, runs: 200 }, outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object'] } } } };
function findImports(p) { const full = path.join(dir, 'node_modules', p); if (fs.existsSync(full)) return { contents: fs.readFileSync(full, 'utf8') }; return { error: 'File not found: ' + p }; }
const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));
if (output.errors) { for (const e of output.errors) console.log(e.severity, e.formattedMessage || e.message); if (output.errors.some(e => e.severity === 'error')) process.exit(1); }
const c = output.contracts['TalvioToken.sol']['TalvioToken'];
fs.writeFileSync(path.join(__dirname, 'TalvioToken.json'), JSON.stringify({ abi: c.abi, bytecode: '0x' + c.evm.bytecode.object, deployedBytecode: '0x' + c.evm.deployedBytecode.object }, null, 2));
console.log('TalvioToken', 'CREATION_BYTES', c.evm.bytecode.object.length / 2, 'DEPLOYED_BYTES', c.evm.deployedBytecode.object.length / 2);
console.log('FUNCTIONS', c.abi.filter(x => x.type === 'function').map(x => x.name).join(','));
console.log('OK');
