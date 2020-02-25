This repository is a downstream fork of [ethereum/discv4-dns-list](https://github.com/ethereum/discv4-dns-lists)
which includes DNS discovery information for ETC networks.

Source for the devp2p tool mentioned below which support ETC network filters
can be found at [etclabscore/core-geth](https://github.com/etclabscore/core-geth).

Rather than _ethdisco.net_, the records held under this repository are published to the __blockd.info__ DNS name.

---

# discv4-dns-lists

This repository contains [EIP-1459][EIP-1459] node lists built by the go-ethereum devp2p
tool. These lists are published to the ethdisco.net blockd.info DNS name.

The nodes in the lists are found by crawling the Ethereum node discovery DHT. The entire
output of the crawl is available in the `all.json` file. We create lists for specific
blockchain networks by filtering `all.json` according to the ["eth" ENR entry value][eth-entry]
provided by each node.

If you want your node in the list, simply run your client and make sure it is reachable
through discovery. The crawler will pick it up and sort it into the right list
automatically.

[EIP-1459]: https://eips.ethereum.org/EIPS/eip-1459
[eth-entry]: https://github.com/ethereum/devp2p/blob/master/enr-entries/eth.md
