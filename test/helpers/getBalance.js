export default async function getBalance (addr) {
  return web3.eth.getBalance(addr);
}
