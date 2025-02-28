#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                   R e v i s i o n   C o n t r o l  -  G i t
# ============================================================================ #

# Primary revision control system
#
# if svn.sh and hg.sh functions are enabled, detects and calls svn and mercurial commands if inside those repos so some of the same commands work dynamically

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

if [ -f ~/.github_token  ]; then
    GITHUB_TOKEN="$(cat ~/.github_token)"
    export GITHUB_TOKEN
fi

if [ -f ~/.gitlab_token  ]; then
    GITLAB_API_PRIVATE_TOKEN="$(cat ~/.gitlab_token)"
    export GITLAB_API_PRIVATE_TOKEN
fi
#if [ -z "${GITLAB_API_ENDPOINT:-}" ]; then
#    export GITLAB_API_ENDPOINT="https://gitlab.com/api/v4"
#fi

if ! type basedir &>/dev/null; then
    # shellcheck disable=SC1090
    . "$bash_tools/.bash.d/functions.sh"
fi

if type -P gh &>/dev/null; then
    autocomplete gh -s
fi

# find out who your 'gh' CLI is authenticating as - useful if you have multiple Personal Access Tokens for different environments
alias githubwhoami='github_api.sh /user | jq -r .login'
alias ghwhoami='github_api.sh /user | jq -r .login'

# set location where you check out all the github repos
export github=~/github

export GIT_PAGER="less ${LESS:-}"
# shellcheck disable=SC2230
#if [ -z "${GIT_PAGER:-}" ] && \
if type -P diff-so-fancy &>/dev/null; then
    # pre-loading a pattern to 'n' / 'N' / '?' / '/' search through will force you in to pager and disregard -F / --quit-if-one-screen
    #export GIT_PAGER="diff-so-fancy --color=yes | less -RFX --tabs=4 --pattern '^(Date|added|deleted|modified): '"
    export GIT_PAGER="diff-so-fancy --color=yes | $GIT_PAGER"
fi

alias gitconfig="\$EDITOR ~/.gitconfig"
alias gitignore="\$EDITOR ~/.gitignore_global"
alias gitrc=gitconfig
# false positive, not calling this from xargs
# shellcheck disable=SC2032
#alias add=gitadd
add(){ gitadd "$@"; }
alias gadd='git add'
alias import=gitimport
alias co=checkout
alias commit="git commit"
alias clone="git clone"
alias cherry-pick="git cherry-pick"
alias gitci=commit
alias ci=commit
alias gitco=checkout
alias up=pull
alias u=up
alias uu="GIT_PULL_IN_BACKGROUND=1 u"
alias pu=push
alias gitp="git push"
alias gdiff="git diff"
# bypasses diff-so-fancy, could also just pipe through | cat to disable pager and color effects
alias gdiff2="git --no-pager diff"
alias gdiffc="git diff --cached"
alias gdiffm="gdiff origin/master.."
alias gd=gdiff
alias gdc=gdiffc
alias gdo=gdiffm
alias branch="githg branch"
alias br=branch
alias fetch='git fetch'
alias stash="git stash"
alias tag="githg tag"
alias gitlogwc='git log --oneline | wc -l'
alias um=updatemodules
#type browse &>/dev/null || alias browse=gbrowse
alias gbrowse=gitbrowse
alias gb='gitbrowse'
#alias gh='gitbrowse github'  # clashes with GitHub CLI
alias gl='gitbrowse gitlab'
alias bb='gitbrowse bitbucket'
alias azd='gitbrowse azure'
alias github_actions='gitbrowse github actions'
alias github_workflows='github_actions'
alias gha='github_actions'
alias ghw='github_workflows'
alias wf='cd .github/workflows/'
alias ggrep="git grep"
alias remotes='git remote -v'
alias remote='remotes'
# much quicker to just 'cd $github; f <pattern>'
#githubls(){
#    # GitHub is svn compatible, use this to list files remotely
#    svn ls "https://github.com/$1.git/branches/master/"
#}
#githubgrep(){
#    for repo in $(sed 's/#.*//;s/:.*//;/^[[:space:]]*$/d' "$srcdir/setup/repos.txt"); do
#        githubls "HariSekhon/$repo"
#    done |
#    grep "$@"
#}

# git fetch -p or git remote prune origin
#alias prune="co master; git pull --no-edit; git remote prune origin; git branch --merged | grep -v -e '^\\*' -e 'master' | xargs git branch -d"
removed_branches(){
    git remote prune origin >&2
    git branch -vv |
    cut -c 3- |
    awk '$4 ~ /gone\]/ {print $1}'
}
alias prune="removed_branches | xargs -r git branch -d"

# don't use this unless you are a git pro and understand unwinding history and merge conflicts
alias GRH="git reset HEAD^"

alias master="switchbranch master"
alias prod="switchbranch prod"
alias production="switchbranch production"
alias staging="switchbranch staging"
alias stage=staging
alias dev="switchbranch dev"

# edit all GitHub READMEs
alias readmes="\$EDITOR \$(git_foreach_repo.sh echo '\$PWD/README.md')"

# equivalent of hg root
git_root(){
    git rev-parse --show-toplevel
}

gitgc(){
    if ! [ -d .git ]; then
        echo "not at top of a git repo, not .git/ directory found"
        return 1
    fi
    du -sh .git
    git gc --aggressive
    du -sh .git
}

gitbrowse(){
    local filter="${1:-.*}"
    local path="${2:-}"
    local url_base
    url_base="$(git remote -v |
                grep "$filter" |
                awk '/git@|https:/{print $2}' |
                head -n1 |
                sed 's|^ssh://||;
                     s|^https://.*@||;
                     s|^https://||;
                     s/^git@ssh.dev.azure.com:v3/dev.azure.com/;
                     s|^git@||;
                     s|^|https://|;
                     s/\.git$//;' |
                perl -pe 's/:(?!\/\/)/\//')"
    if [[ "$url_base" =~ dev.azure.com ]]; then
        url_base="${url_base%/*}/_git/${url_base##*/}"
    fi
    if [ $# -gt 0 ] &&
       [ -z "$url_base" ]; then
        echo "git remote url not found for $filter"
        return 1
    fi
    browser "$url_base/$path"
}

install_git_completion(){
    if ! [ -f ~/.git-completion.bash ]; then
        wget -O ~/.git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    fi
}

# shellcheck disable=SC1090
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# usage: gi python,perl,go
#        gi list
gitignore_api(){
    local url
    local langs
    local options=()
    local args=()
    # noop - set to use 'tr' to separate items to newlines when given the 'list' arg
    local commas_to_newlines="cat"
    for arg; do
        if [ "$arg" = -- ]; then
            options+=("$arg")
        else
            args+=("$arg")
        fi
    done
    # take args 'python perl', store as 'python,perl' for the API call
    langs="$(IFS=, ; echo "${args[*]}")"
    url="https://www.gitignore.io/api/$langs"
    if [ "$langs" = "list" ]; then
        commas_to_newlines="tr ',' '\\n'"
    fi
    {
    if hash curl 2>/dev/null; then
        curl -sSL "${options[*]}" "$url"
    elif hash wget 2>/dev/null; then
        wget -O - "${options[*]}" "$url"
    fi
    } | eval "$commas_to_newlines"
    echo
}
alias gi=gitignore_api

git_user_repo(){
    git remote -v | awk '{print $2}' | head -n1 | git_repo_strip
}

git_repo(){
    git_user_repo | sed 's|.*/||'
}

github_user_repo(){
    git remote -v | awk '/github.com/{print $2}' | head -n1 | git_repo_strip
}

github_repo(){
    github_user_repo | sed 's|.*/||'
}

git_repo_strip(){
    git_repo_strip_auth | sed 's|.*\.[^:/]*[:/]||; s/\.git[[:space:]]*$//'
}

git_repo_strip_auth(){
    sed 's/[[:alnum:]]*@//'
}

isGit(){
    local target=${1:-.}
    # There aren't local .hg dirs everywhere only at top level so this is difficult in bash
    if [ -d "$target/.git" ]; then
        return 0
    elif [ -f "$target" ] &&
         [ -d "${target%/*}/.git" ]; then
        #-o "$target/../.git" -o "${target%/*}/../.git" ]; then
        return 0
    else
        # This is because git command doesn't return correctly when running from outside git root, complains there is not .git
        if [ -d "$target" ]; then
            pushd "$target" >/dev/null || return 1
            if [ -n "$(git log -1 . 2>/dev/null)" ]; then
                # shellcheck disable=SC2164
                popd &>/dev/null
                return 0
            fi
        else
            pushd "$(dirname "$target")" >/dev/null || return 1
            #if git log -1 "$target" 2>/dev/null | grep -q '.*'; then
            if [ -n "$(git log -1 "$(basename "$target")" 2>/dev/null)" ]; then
                # shellcheck disable=SC2164
                popd &>/dev/null
                return 0
            fi
        fi
        # shellcheck disable=SC2164
        popd &>/dev/null
        return 2
    fi
}


st(){
  # shellcheck disable=SC2086
  {
    local target="${1:-.}"
    shift
    if ! [ -e "$target" ]; then
        echo "$target does not exist"
        return 1
    fi
    local target_basename
    local target_dirname
    target_basename="$(basename "$target")"
    target_dirname="$(dirname "$target")"
    #if [ -f "Vagrantfile" ]; then
    #    echo "> vagrant status"
    #    vagrant status
    # shellcheck disable=SC2166
    if [ "$target" = "." ] &&
       [ "${PWD##*/}" = github ]; then
        hr
        for x in "$target"/*; do
            [ -d "$x" ] || continue
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            if git remote -v | grep -qi harisekhon; then
                echo "> GitHub: git status $x $*"
                git status . "$@"
                echo
                hr
                echo
            fi
            # shellcheck disable=SC2164
            popd &>/dev/null
        done
    elif { [ "$target" = "." ] &&
         [ "${PWD##*/}" = work ] ; } ||
         grep -Fxq "$PWD" <<< "${GIT_BASEDIRS:-}"; then
         #ls ./*/.git &>/dev/null; then  # matches inside repos with submodules unfortunately
        hr
        for x in "$target"/*; do
            [ -d "$x" ] || continue
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            echo "> Work: git status $x $*"
            git status . "$@"
            echo
            hr
            echo
            # shellcheck disable=SC2164
            popd &>/dev/null
        done
    elif isGit "$target"; then
        if [ -d "$target" ]; then
            pushd "$target" >/dev/null || { echo "Error: failed to pushd to $target"; return 1; }
            echo "> git stash list" >&2
            git stash list && echo
            #"$bash_tools/git_summary_line.sh"
            echo "> git status $target $*" >&2
            #git -c color.status=always status -sb . "$@"
            git -c color.status=always status . "$@"
            echo "Revision: $(git rev-parse HEAD)"
        else
            pushd "$target_dirname" >/dev/null || { echo "Error: failed to pushed to '$target_dirname'"; return 1; }
            echo "> git status $target $*" >&2
            #"$bash_tools/git_summary_line.sh"
            git -c color.status=always status "$target_basename" "$@"
        fi
        #git status "$target" "${*:2}"
        # shellcheck disable=SC2164
        popd &>/dev/null
    elif type isHg &>/dev/null && isHg "$target"; then
        echo "> hg status $target $*" >&2
        hg status "$target" "$@" | grep -v "^?"
        # to see relative paths instead of the default absolute paths
        #hg status "$(hg root)"
    elif type isSvn &>/dev/null && isSvn "$target"; then
        echo "> svn st $*" >&2
        svn st --ignore-externals "$target" "$@" | grep -v -e "^?" -e "^x";
    else
        echo "not a revision controlled resource as far as bashrc can tell"
    fi
  } |
  # more calls less on Mac, and gets stuck in interactive mode ignoring the less alias switches
  #more -R -n "$((LINES - 3))"
  #less -RFX
  eval ${GIT_PAGER:-cat}
}

stq(){
    st "$@" | grep --color=no -e "=======" -e branch -e GitHub | eval "${GIT_PAGER:-cat}"
}

# disabling this as I don't use Mercurial or Svn any more,
# replacing with simpler function below that will pass through more things like --rebase
#pull(){
#    local target="${1:-.}"
#    if ! [ -e "$target" ]; then
#        echo "$target does not exist"
#        return 1
#    fi
#    local target_basename
#    target_basename="$(basename "$target")"
#    # shellcheck disable=SC2166
#    if [ "$target_basename" = "github" ] || [ "$target" = "." -a "$(pwd)" = "$github" ]; then
#        for x in "$target"/*; do
#            [ -d "$x" ] || continue
#            # get last character of string
#            [ "${x: -1}" = 2 ] && continue
#            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
#            if git remote -v | grep -qi harisekhon; then
#                echo "> GitHub: git pull $x ${*:2}"
#                git pull "${@:2}"
#                echo
#                echo "> GitHub: git submodule update --init --recursive"
#                git submodule update --init --recursive
#                echo
#            fi
#            # shellcheck disable=SC2164
#            popd &>/dev/null
#        done
#        return
#    elif isGit "$target"; then
#        pushd "$target" >/dev/null &&
#        echo "> git pull -v ${*:2}" >&2
#        git pull -v "${@:2}"
#        echo "> git submodule update --init --recursive"
#        git submodule update --init --recursive
#        #local orig_branch=$(git branch | awk '/^\*/ {print $2}')
#        #for branch in $(git branch | cut -c 3- ); do
#        #    git checkout -q "$branch" &&
#        #    echo -n "$branch => " &&
#        #    git pull -v
#        #    echo
#        #    echo
#        #done
#        #git checkout -q "$orig_branch"
#        # shellcheck disable=SC2164
#        popd &>/dev/null
#    elif type isHg &>/dev/null && isHg "$target"; then
#        pushd "$target" >/dev/null &&
#        echo "> hg pull && hg up" >&2  &&
#        hg pull && hg up
#        # shellcheck disable=SC2164
#        popd &>/dev/null
#    elif type isSvn &>/dev/null && isSvn "$target"; then
#        echo "> svn up $target" >&2
#        svn up "$target"
#    else
#        echo "not a revision controlled resource as far as bashrc can tell"
#        return 1
#    fi
#}

# simpler replacement function to above
# shellcheck disable=SC2120
pull(){
    # shellcheck disable=SC2166
    if [ "${PWD##*/}" = github ]; then
        for x in *; do
            [ -d "$x/.git" ] || continue
            # get last character of string - don't pull blah2, as I use them as clean checkouts
            [ "${x: -1}" = 2 ] && continue
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            if git remote -v | grep -qi "${GITHUB_USER:-${GIT_USER:-${USER:-}}}"; then
                hr
                echo "> GitHub $x: git pull --all --no-edit $*"
                #echo "> GitHub $x: git submodule update --init --recursive"
                if [ -n "${GIT_PULL_IN_BACKGROUND:-}" ]; then
                    git_pull "$@" &
                else
                    git_pull "$@"
                fi
            fi
            # shellcheck disable=SC2164
            popd &>/dev/null
        done
    elif [ "${PWD##*/}" = work ] ||
         grep -Fxq "$PWD" <<< "${GIT_BASEDIRS:-}"; then
         #ls ./*/.git &>/dev/null; then  # matches inside repos with submodules unfortunately
        for x in *; do
            [ -d "$x" ] || continue
            hr
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            echo "> Work $x: git pull --all --no-edit $*"
            #echo "> work $x: git submodule update --init --recursive"
            if [ -n "${GIT_PULL_IN_BACKGROUND:-}" ]; then
                git_pull "$@" &
            else
                git_pull "$@"
            fi
            # shellcheck disable=SC2164
            popd &>/dev/null
        done
    else
        echo "> git pull --all --no-edit $*"
        echo "> git submodule update --init --recursive"
        git_pull "$@"
    fi
}

git_pull(){
    echo
    git pull --all --no-edit "$@"
    echo
    git submodule update --init --recursive
    echo
}

checkout(){
    if isGit "."; then
        git checkout "$@";
    else
        echo "not a Git checkout, cannot switch to branch $*"
        return 1
    fi
}

_gitaddimport() {
    local action="$1"
    shift;
    [ -z "$*" ] && return 1
    local basedir;
    basedir="$(basedir "$@")" && local trap_codes="INT ERR";
    # shellcheck disable=SC2064,SC2086
    trap "popd &>/dev/null; trap - $trap_codes; return 1 2>/dev/null" $trap_codes;
    pushd "$basedir" > /dev/null || return 1;
    # shellcheck disable=SC2086
    local filenames
    filenames="$(strip_basedirs "$basedir" "$@")";
    while read -r filename; do
        if ! [ -e "$filename" ]; then
            echo "ERROR: $filename does not exist" >&2
            return 1
        elif git status -s "$filename" | grep -q '^[?A]'; then
            git add "$filename" &&
            git commit -m "$action $filename" "$filename"
        elif git status -s "$filename" | grep -q '^.M'; then
            echo "ERROR: '$filename' already in git, but has changes, commit as an update instead" >&2
            return 1
        elif git status --ignored -s "$filename" | grep -q '^!!'; then
            echo "ERROR: '$filename' is ignored!!! =>  $(git check-ignore -v "$filename")" >&2
            return 1
        else
            echo "ERROR: '$filename' already in git" >&2
            return 1
        fi
    done <<< "$filenames"
    popd > /dev/null || :
}

gitadd(){
    _gitaddimport added "$@"
}

gitimport(){
    _gitaddimport imported "$@"
}


# shellcheck disable=SC2086
gitu(){
    if [ -z "$1" ]; then
        echo "usage: gitu <file> <file2> ..."
        return 3
    fi
    local basedir
    local trap_codes="INT ERR"
    # expand now
    # shellcheck disable=SC2064
    trap "popd &>/dev/null; trap - $trap_codes; return 1 2>/dev/null" $trap_codes
    #targets=("$(strip_basedirs "$basedir" "$targets")")
    for filename in "$@"; do
        # follow symlinks to the actual files because diffing symlinks returns no changes
        filename="$(resolve_symlinks "$filename")"
        # go to the highest directory level to git diff inside the git repo boundary, otherwise git diff will return nothing
        basedir="$(basedir "$filename")" || return 1
        pushd "$basedir" >/dev/null || return 1
        # XXX: needs -s to return the basename and not the full name
        changed_files="$(git status --porcelain -s "${filename##*/}" |
                 grep -e '^M' -e '^.M' |
                 sed 's/^...//')"
        # while read line would auto-accepting the readline and commit without prompt :-/
        for changed_filename in $changed_files; do
            basename="${changed_filename##*/}"
            diff="$(git diff --color=always -- "$changed_filename"; git diff --cached --color=always -- "$changed_filename")"
            if [ -z "$diff" ]; then
                continue
            fi
            echo "$diff" | more -R
            echo
            read -r -p "Hit enter to commit '$changed_filename' or Control-C to cancel" _
            echo
            git add -- "$changed_filename" &&
            echo "committing $changed_filename" &&
            git commit -m "updated $basename" -- "$changed_filename" ||
            return 1
        done
        popd &>/dev/null || :
    done
    trap - $trap_codes
}
gituu(){
    # avoiding xargs due to function reference:
    # gxargs: gitu: No such file or directory
    eval gitu "$(
        git status --porcelain -s . |
        grep -e '^M' -e '^.M' |
        sed 's/^...//' |
        while read -r filename; do
            echo "\"$filename\""
        done
    )"
}

#githgu(){
#    target="${1:-.}"
#    #count=0
#    while [ -L "$target" ]; do
#        #target="$(readlink "$target")"
#        #let count+=1
#        #if [ $count -gt 10 ]; then
#        #    echo "looping over links more than 10 times in hggitu! "
#        #    exit 2
#        #fi
#        echo "$target is a symlink! "
#        return 1
#    done
#    if ! [ -e "$target" ]; then
#        echo "$target does not exist"
#        return 1
#    fi
#    if isGit "$target"; then
#        echo "> git" >&2
#        #if [ -d "$target" ]; then
#        #    pushd "$target" >/dev/null
#        #else
#        #    pushd "$(dirname "$target")" >/dev/null
#        #fi
#        #"$srcdir2/gitu" "${target##*/}" &&
#        gitu "$target"
#        #popd &>/dev/null
#    elif type isHg &>/dev/null && isHg "$target"; then
#        echo "> hg" >&2
#        #if [ -d "$target" ]; then
#        #    pushd "$target" >/dev/null
#        #else
#        #    pushd "$(dirname "$target")" >/dev/null
#        #fi
#        #"$srcdir2/hgu" "${target##*/}" &&
#        hgu "$target"
#        #popd &>/dev/null
#    # Not supporting SVN any more
#    #elif type isSvn &>/dev/null && isSvn "$target"; then
#    #    echo "> svn" >&2
#    #    svnu "$target"
#    else
#        echo "not a revision controlled resource as far as bashrc can tell"
#        return 1
#    fi
#}

push(){
    # shellcheck disable=SC2119
    pull || return 1
    if isGit .; then
        echo "> git push $*"
        #for remote in $(git remote); do
        #    git push -v $remote $@
        #done
        # can't be sure where we're pushing without parsing the command args, so omit for now
        if [ $# -eq 0 ]; then
            echo "pushing to:"
            # uniq_ordered.pl from my DevOps-Perl-tools repo or
            # uniq2 from my DevOps-Golang-tools repo would be better here
            # but not sure I want to create a dependency on that
            # unix's standard uniq unfortnately will only deduplicate adjacent lines but should be good enough in most cases
            git remote -v | awk '/^origin/{print $1"\t"$2}' | sed 's,://.*@,://,' | uniq
            echo
        fi
        # exposes your Github / GitLab / Bitbucket tokens on the screen, not secure, use printing above instead
        #git push -v "$@"
        git push "$@"
    elif type isHg &>/dev/null && isHg .; then
        echo "> hg push $*"
        hg push "$@"
    else
        echo "not in a Git or Mercurial controlled directory"
        return 1
    fi
}
pushu(){
    push "$@" --set-upstream origin "$(git branch | awk '/^\*/{print $2}')"
}

switchbranch(){
    if isGit "."; then
        git checkout "$1";
    elif type isHg &>/dev/null && isHg "."; then
        hg update "$1"
    else
        echo "not a Git / Mercurial checkout, cannot switch to branch $1"
        return 1
    fi
}

gitrm(){
    git rm "$@" &&
    git commit -m "removed $*" "$@"
}

gitrename(){
    git mv "$1" "$2" &&
    git commit -m "renamed $1 to $2" "$1" "$2"
}

gitmv(){
    git mv "$1" "$2" &&
    git commit -m "moved $1 to $2" "$1" "$2"
}

gitd(){
    git diff "${@:-.}"
}

gitadded(){
    git log --name-status "$@" |
    grep -e '^A[^u]' -e '^Date' |
    grep -B 1 '^A' |
    less
}

# doesn't need pipe | less, git drops you in to less anyway
gitl(){
    git log --all --graph --decorate --name-status "$@"
}

gitlp(){
    git log -p "$@"
}

gitl2(){
    git log --all --graph --decorate --stat "$@"
}

gitl3(){
    git log --pretty=format:"%n%an => %ar%n%s" --name-status "$@"
}

githg(){
    if isGit .; then
        git "$@"
    elif type isHg &>/dev/null && isHg .; then
        hg "$@"
    else
        echo "not a Git/Mercurial checkout"
        return 1
    fi
}

retag(){
    local tag1="$1"
    local checksum="$2"
    local additional_tags="${*:2}"
    for tag in $tag1 $additional_tags; do
        git tag -d "$tag" || :
        echo "Creating git tag '$tag'"
        # quoting checksum causes failure with unrecognized checksum ''
        git tag "$tag" "$checksum"
        git tag |
        grep -qF "$tag" ||
            echo "FAILED"
    done
}

gitfind(){
    local refids
    refids="$(git log --all --oneline | grep "$@" | awk '{print $1}')"
    printf 'Branches:\n\n'
    for refid in $refids; do
        git branch --contains "$refid"
    done | sort -u
    printf '\nTags:\n\n'
    for refid in $refids; do
        git tag --contains "$refid"
    done | sort -u
}

# useful for smaller things:
#
# git submodule foreach --recursive 'git checkout master && git pull'
#
updatemodules(){
    if isGit .; then
        git pull --no-edit
        #git submodule update --init --remote
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
                pushd "$submodule" || continue
                git stash
                git checkout master
                git pull --no-edit
                git submodule update
                # shellcheck disable=SC2164
                popd
            fi
        done
        echo
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ] && ! git status "$submodule" | grep -q nothing; then
                git commit -m "updated $submodule" "$submodule" || break
            fi
        done &&
        make updatem ||
        echo FAILED
        echo
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
                pushd "$submodule" || continue
                git stash pop
                # shellcheck disable=SC2164
                popd
            fi
        done
    else
        echo "Not a Git repository! "
        return 1
    fi
}

upl(){
    local repos="pylib pytools lib tools bash-tools nagios-plugins npk"
    # pull all repos first so can handle merge requests if needed
    for repo in $repos; do
        echo
        echo "* Pulling latest repo changes:  $repo"
        echo
        pushd "$github/$repo" &&
        git pull --no-edit &&
        popd &&
        hr || return 1
    done
    echo
    echo "UNATTEND FROM HERE"
    echo
    for repo in $repos; do
        echo
        echo "* Performing latest submodule updates:  $repo"
        echo
        pushd "$github/$repo" &&
        ! updatemodules 2>&1 | tee /dev/stderr | grep -e ERROR -e FAIL &&
        git push &&
        popd &&
        hr || return 1
    done
}

#stagemerge(){
#    if isGit "."; then
#        git checkout prod    && git pull &&
#        git checkout staging && git pull &&
#        git merge prod
#        git checkout prod
#    else
#        echo "Not a Git working copy";
#    fi
#}

gitdiff(){
    local filename="${1:-}"
    [ -n "$filename" ] || { echo "usage: gitdiff filename"; return 1; }
    git diff "$filename" > "/tmp/gitdiff.tmp"
    diffnet.pl "/tmp/hgdiff.tmp"
}

git_author_names(){
    git log --all --pretty=format:"%an" | sort | uniq -c | sort -k1nr | less
}

git_author_emails(){
    git log --all --pretty=format:"%ae" | sort | uniq -c | sort -k1nr | less
}

git_author_names_emails(){
    git log --all --pretty=format:"%an %ae" | sort | uniq -c | sort -k1nr | less
}

git_authors(){
    git_author_emails
}

git_commit_count(){
    # interestingly, even on 10,000 commit repos, there are no duplicate short hashes shown from:
    # git log --all --pretty=format:"%h" | sort | uniq -d
    git log --all --pretty=format:"%h" | wc -l
}

git_revert_typechange(){
    # want splitting to separate filenames
    # shellcheck disable=SC2046
    co $(git status --porcelain -s "${1:-.}" | awk '/^.T/{print $2}')
}

git_rm_untracked(){
    if [ $# -lt 1 ]; then
        echo "usage: rm_untracked <target_dir_or_files_or_glob>"
        return 1
    fi
    # iterate on explicit targets only
    # intentionally not including current directory to avoid accidentally wiping out untracked files - you must specify "rm_untracked ." if you really intend this
    for x in "${@:-}"; do
        git status --porcelain -s --untracked-files=all "$x" |
        # this breaks the correct spacings for Spotify playlist filenames
        #awk '/^\?\?/{$1=""; print}' |
        grep '^??' |
        sed 's/^?? //' |
        while read -r filename; do
            # git status --porcelain double quotes file paths when containing unicode chars which are representated in \xxx format
            # you must set 'git config --global core.quotePath false' for this to work properly
            #
            # this doesn't help because you are still stuck with \xxx chars throughout
            #filename="${filename#\"}"
            #filename="${filename%\"}"
            rm -v "$filename" || break
        done
    done
}

# example of usage of this in the function below - make sure to put '$repo' or "\$repo" somewhere in the argument body to make use of the iteration variable
foreachrepo(){
    local repolist="${REPOLIST:-$bash_tools/setup/repos.txt}"
    while read -r repo; do
        eval "$@"
    done < <(sed 's/#.*$//; s/.*://; /^[[:space:]]*$/d' "$repolist")
}

github_authors(){
    # deferring expansion into loop
    # shellcheck disable=SC2016
    foreachrepo 'echo "repo: $repo"; pushd "$github/$repo" >/dev/null || return 1; git_authors; popd >/dev/null || return 1; echo' | ${less:-less}
}

merge_conflicting_files(){
    # merge conflicts:
    #
    # UU = both updated
    # AA = both added
    #
    git status --porcelain | awk '/^UU|^AA/{$1=""; print}'
}

merge_deleted_files(){
    git status --porcelain | awk '/^DU/{$1=""; print}'
}

# useful for Dockerfiles merging lots of branches
#
# while ! make mergemasterpull; do fixmerge "merged master"; done
#
fixmerge(){
    local msg="${*:-merged}"
    local merge_conflicted_files
    local merge_deleted_files
    merge_deleted_files="$(merge_deleted_files)"
    if [ -n "$merge_deleted_files" ]; then
        # false positive, not passing add function/alias add to git
        # shellcheck disable=SC2033
        xargs git add <<< "$merge_deleted_files"
    fi
    merge_conflicted_files="$(merge_conflicting_files)"
    if [ -n "$merge_conflicted_files" ]; then
        # shellcheck disable=SC2086
        "$EDITOR" $merge_conflicted_files &&
        git add $merge_conflicted_files
    fi
    git ci -m "$msg"
}

buildkite_browse(){
    if [ -z "${BUILDKITE_ORGANIZATION:-}" ]; then
        echo "\$BUILDKITE_ORGANIZATION not set"
        return 1
    fi
    local repo
    repo="$(git_repo | tr '[:upper:]' '[:lower:]')"
    browser "https://buildkite.com/$BUILDKITE_ORGANIZATION/$repo"
}
# bk is used by buildkite cli now
alias bkb=buildkite_browse
