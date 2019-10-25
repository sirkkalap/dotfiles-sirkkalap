alias curlh="curl -i -v -s -o /dev/null 2>&1"
alias dnetwork="docker network ls -q | xargs docker network inspect --format='{{.Name}} {{range .IPAM.Config}}{{.Subnet}}{{end}}'"

# Remove prezto babysitting me
alias cp='nocorrect cp'
alias ln='nocorrect ln'
alias mv='nocorrect mv'
alias rm='nocorrect rm'
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias rmi="${aliases[rm]:-rm} -i"
