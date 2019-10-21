alias curlh="curl -i -v -s -o /dev/null 2>&1"
alias dnetwork="docker network ls -q | xargs docker network inspect --format='{{.Name}} {{range .IPAM.Config}}{{.Subnet}}{{end}}'"
