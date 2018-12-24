# jest-watch-bug

`zsh` is needed for the script to run. The script prints open watches in the `node_modules`
directory, as well as the process that opened the watch. `awk` here filters for the
processes that are watching a `node_modules` directory. `tac` reverses the line order,
so that the line containing the process name is printed last instead of first for easy reading.

1. `npm i`
2. `npx jest --watch`
3. `zsh processes_with_watches.sh | awk -v RS= -v ORS='\n\n' '/node_modules\//' | tac`

Observe that the `jest` process maintains watches in `node_modules` files despite
it being blacklisted in the `watchPathIgnorePatterns` configuration option in `package.json`.
