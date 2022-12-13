add-content -path c:/users/username/.ssh/config -value @'

Host  ${hostname}
  HostName ${hostname}
  User ${user}
  IdentityFile ${identityfile}