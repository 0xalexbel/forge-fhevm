# forge-fhevm
A forge library to run Zama's fhevm 

## Remappings

Warning: The 2 following remapping lines are importants

```bash
"fhevm/=dependencies/forge-fhevm-0.6.0-5/src/debug/fhevm/"
"forge-fhevm/=dependencies/forge-fhevm-0.6.0-5/"
```

## foundry.toml

```toml
[profile.default]
solc = "0.8.24"
evm_version = "cancun"
src = "src"
out = "out"
libs = ["dependencies", "node-modules"]
remappings= [
    "forge-std/=dependencies/forge-std-1.9.3/",
    "forge-fhevm/=dependencies/forge-fhevm-0.6.0-5/",
    "fhevm/=dependencies/forge-fhevm-0.6.0-5/src/debug/fhevm/"
]

[dependencies]
forge-std = "1.9.3"
forge-fhevm = { version = "0.6.0-5", git = "https://github.com/0xalexbel/forge-fhevm.git" }

[soldeer]
remappings_version = false
```

## Development

```bash
# restore foundry.toml
mv ./foundry.toml.dev ./foundry.toml

# restore remappings.txt (for vscode)
mv ./remappings.txt.dev ./remappings.txt

# install dependencies
forge soldeer install

# install dependencies (fhevm-core-contracts)
npm install

# run tests
forge test
```

