function gita {
    git status -s;
    git add --all;
  }
  function gitap {
    #Param([switch] $Amend)
    git status -s;
    if ($LASTEXITCODE -eq 0) {
      git add --all;
      #if ($Amend) {
      #  git commit --amend
      #}
      #else {
        git commit -m "small fixes";
      #}
      $cb = git branch --show-current;
      git push origin $cb;
    } 
  }
  
  function gitt { set-Location -Path (git rev-parse --show-toplevel) }