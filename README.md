# forge-fhevm
A forge library to run Zama's fhevm 

## foundry.toml

```toml
[profile.default]
solc = "0.8.24"
evm_version = "cancun"
src = "src"
out = "out"
libs = ["dependencies"]
remappings= [
    "@openzeppelin/contracts-upgradeable/=dependencies/@openzeppelin-contracts-upgradeable-5.0.2/",
    "@openzeppelin/contracts/=dependencies/@openzeppelin-contracts-5.0.2/",
    "fhevm/=dependencies/forge-fhevm-0.6.0-3/",
    "forge-fhevm/=dependencies/forge-fhevm-0.6.0-3/",
    "forge-std/=dependencies/forge-std-1.9.3/"
]

[dependencies]
forge-std = "1.9.3"
"@openzeppelin-contracts" = { version = "5.0.2" }
"@openzeppelin-contracts-upgradeable" = { version = "5.0.2" }
forge-fhevm = { version = "0.6.0-4", git = "https://github.com/0xalexbel/forge-fhevm.git" }

[soldeer]
remappings_version = false
```

## Development

```bash
npm install
forge soldeer install
```

