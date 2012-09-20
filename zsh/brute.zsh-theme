# zsh prompt theme for use with oh-my-zsh
# ethan schoonover / e@ejas.net
#
# heavily indebted to Seth House at eseth.com
# 
# REQUIREMENTS:
# zsh 4.3.11 or above! VCS_info (zshcontrib) requries functions from that
# version or greater

# TODO: known bugs:
# this is a zshcontrib / vcsinfo bug, I'm pretty sure:
# create a test dir, touch a file, git init, and the file show up as a new,
# untracked file. however if you then git add . , it will be added to the index
# but will not show up as a staged changed. this only seems to occur up until
# the first actual commit.

# BRUTE Options
# BRUTECOLORS=16

# zsh options
setopt multibyte
setopt prompt_subst     # param expansion, cmd subst, arith expans in prompts
setopt prompt_percent   # allow % escaped sequences to be expanded
unsetopt prompt_bang    # ! for history interferes with my change indicators

# zsh functions autoload
autoload -U add-zsh-hook
autoload -Uz vcs_info
autoload -U colors && colors
autoload -U promptinit  # not used right now...

# the following addresses problems with the oh-my-zsh vim plugin eating the
# line above the prompt with resetting it. I've had no negative impact from
# nullifying the function of zle-line-init
function zle-line-init { }

# debug mode
# zstyle ':vcs_info:*+*:*' debug true

# JANUS     16/8 TERMCOLOR  HEX     XTERM   XTERM HEX   L*A*B
# base03     8/4 br black   #00151b   233   #121212     05 -07 -07
# base02     0/4 black      #17282e   234   #1c1c1c     15 -06 -06
# base01    10/7 br green   #3b494e   236   #303030     30 -05 -05
# base00    11/7 br yellow  #5e6d73   239   #4e4e4e     45 -05 -05
# base0     12/6 br blue    #77878c   242   #6c6c6c     55 -05 -05
# base1     14/4 br cyan    #9eaeb4   246   #949494     70 -05 -05
# base2      7/7 white      #d2d5cf   252   #d0d0d0     85 -02  03
# base3     15/7 br white   #f7f0dd   230   #ffffd7     95  00  10
# green      2/2 green      #93a707    64   #548700     65 -20  65
# yellow     3/3 yellow     #b58900   172   #d78700     60  10  65
# orange     9/3 br red     #bb3e07   130   #af5f00     45  50  55
# red        1/1 red        #b71818   124   #af0000     35  60  45
# magenta    5/5 magenta    #d92983   161   #d7005f     50  70 -05
# violet    13/5 br magenta #6c71c4    61   #5f5faf     50  15 -45
# blue       4/4 blue       #247ebb    26   #005fd7     50 -10 -40
# cyan       6/6 cyan       #3cafa5    37   #00afaf     65 -35 -05

# use extended color pallete if available
# colors can be output with:
# for code in {000..255}; do print -P -- "$code: %F{$code}Test%f"; done
# (included as a function below for convenience)
local\
    base03\
    base02\
    base01\
    base00\
    base0\
    base1\
    base2\
    base3\
    green\
    yellow\
    orange\
    red\
    magent\
    violet\
    blue\
    cyan\
    white\
    gray\
    black\
    reset\
    colorgo\
    colorwarn\
    colorquery\
    c1\
    c2
if [[ ( $TERM = *256color* || $TERM = *rxvt* ) && $BRUTECOLORS != 16 ]]; then
    c1="%{%F{"
    c2="}%}"
    base03=$c1"233"$c2
    base02=$c1"234"$c2
    base01=$c1"236"$c2
    base00=$c1"239"$c2
    base0=$c1"242"$c2
    base1=$c1"246"$c2
    base2=$c1"252"$c2
    base3=$c1"230"$c2
    green=$c1"64"$c2
    yellow=$c1"172"$c2
    orange=$c1"130"$c2
    red=$c1"124"$c2
    magent=$c1"161"$c2
    violet=$c1"61"$c2
    blue=$c1"26"$c2
    cyan=$c1"37"$c2
    reset="%{${reset_color}%}"
    white=$base3
    gray=$base00
    black=$c1"16"$c2
    colorgo=$green
    colorwarn=$red
    colorquery=$yellow
else
    base03="%{$fg[brightblack]%}"
    base02="%{$fg[black]%}"
    base01="%{$fg[brightgreen]%}"
    base00="%{$fg[brightyellow]%}"
    base0="%{$fg[brightblue]%}"
    base1="%{$fg[brightcyan]%}"
    base2="%{$fg[white]%}"
    base3="%{$fg[brightwhite]%}"
    green="%{$fg[green]%}"
    yellow="%{$fg[yellow]%}"
    orange="%{$fg[brightred]%}"
    red="%{$fg[red]%}"
    magent="%{$fg[magenta]%}"
    violet="%{$fg[brightmagenta]%}"
    blue="%{$fg[blue]%}"
    cyan="%{$fg[cyan]%}"
    reset="%{${reset_color}%}"
    white=$base3
    gray=$base00
    black="%{$fg[black]%}"
    colorgo=$green
    colorwarn=$red
    colorquery=$yellow
    colorgo=$green
    colorwarn=$red
    colorquery=$yellow
fi

function colorlist () {
    for code in {000..255}; do print -P -- "$code: %F{$code}Test%f"; done
}

# how long the hashes should be, maximum
# hashlen will be applied using the zformat builtin (%5.10i, for example,
# the form is actually `%min.maxx') see `The zsh/zutil  Module' in zshmodules(1)
local hashlen
hashlen=8

zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' check-for-changes true

# In normal formats and  actionformats  the  following  replacements  are
# done:
# 
# %s    The VCS in use (git, hg, svn, etc.).
# %b    Information about the current branch.
# %a    An  identifier  that  describes  the action. Only makes sense in
#       actionformats.
# %i    The current revision number or identifier. For hg the  hgrevfor-
#       mat style may be used to customize the output.
# %c    The  string from the stagedstr style if there are staged changes
#       in the repository.
# %u    The string from the unstagedstr  style  if  there  are  unstaged
#       changes in the repository.
# %R    The base directory of the repository.
# %r    The repository name. If %R is /foo/bar/repoXY, %r is repoXY.
# %S    A    subdirectory    within    a    repository.   If   $PWD   is
#       /foo/bar/repoXY/beer/tasty, %S is beer/tasty.
# %m    A "misc" replacement. It is at the discretion of the backend  to
#       decide what this replacement expands to. It is currently used by
#       the hg and git backends to display patch information from the mq
#       and stgit extensions.
# 
# In branchformat these replacements are done:
# 
# %b    The branch name.
# %r    The current revision number or the hgrevformat style for hg.
# 
# In hgrevformat these replacements are done:
# 
# %r    The current local revision number.
# %h    The current 40-character changeset ID hash identifier.
# 
# In patch-format and nopatch-format these replacements are done:
# 
# %p    The name of the top-most applied patch.
# %u    The number of unapplied patches.
# %n    The number of applied patches.
# %c    The number of unapplied patches.

# colors used in vcsinfo
local vcscolor vcshighlight
vcsbase=$reset
vcshighlight=$magent

local FMT_BRANCH FMT_ACTION FMT_COMMON FMT_UNTRACKED FMT_UNSTAGED FMT_STAGED
FMT_BRANCH="${vcsbase}%s ${vcshighlight}%b "
FMT_ACTION="${vcsbase}%s ${vcshighlight}%b:${vcshighlight}%a "
FMT_COMMON="${vcsbase}[%0.${hashlen}i]%u%c%m${reset}"
FMT_UNTRACKED="${colorquery}?${vcsbase}"
FMT_UNSTAGED="${colorquery}!${vcsbase}"
FMT_STAGED="${colorgo}+${vcsbase}"

zstyle ':vcs_info:git*' unstagedstr         "${FMT_UNSTAGED}"
zstyle ':vcs_info:hg*'  unstagedstr         "${FMT_STAGED}"
zstyle ':vcs_info:*'    stagedstr           "${FMT_STAGED}"
zstyle ':vcs_info:*'    formats             "${FMT_BRANCH}${FMT_COMMON}"
zstyle ':vcs_info:*'    actionformats       "${FMT_ACTION}${FMT_COMMON}"
zstyle ':vcs_info:*'    nvcsformats         ""

zstyle ':vcs_info:hg*'  get-bookmarks       true
zstyle ':vcs_info:hg*'  get-mq              true
zstyle ':vcs_info:hg*'  get-unapplied       true
zstyle ':vcs_info:hg*'  patch-format        "mq(%g):%n/%c %p"
zstyle ':vcs_info:hg*'  nopatch-format      "mq(%g):%n/%c %p"
zstyle ':vcs_info:hg*'  branchformat        "%b"
zstyle ':vcs_info:hg*'  hgrevformat         "%r"

# use-simple reduces hg overhead but doesn't show dirty or local rev numbers
# zstyle ':vcs_info:hg*:*' use-simple true

zstyle ':vcs_info:hg*+set-message:*'        hooks hg-branchhead check-untracked\
                                                  add-padding rename-vcs
zstyle ':vcs_info:hg*+set-hgrev-format:*'   hooks hg-storerev hg-shorthash
zstyle ':vcs_info:git*+set-message:*'       hooks check-untracked git-st\
                                                  git-stash add-padding\
                                                  rename-vcs

# store the localrev and global hash for use in other hooks
function +vi-hg-storerev() {
    user_data[localrev]=${hook_com[localrev]}
    user_data[hash]=${hook_com[hash]}
}

# hg: Truncate long hash but also allow for multiple parents
# Hashes are joined with a + to mirror the output of `hg id`.
function +vi-hg-shorthash() {
    if [[ -z ${hook_com[localrev]} ]] ; then
        local -a parents
        parents=( ${(s:+:)hook_com[hash]} )
        parents=( ${(@r:${hashlen}:)parents} )
        hook_com[rev-replace]=${(j:+:)parents}
        ret=1
    fi
}

function +vi-rename-vcs() {
    [[ ${hook_com[vcs_orig]} == git ]] && hook_com[vcs]="±"
    [[ ${hook_com[vcs_orig]} == hg ]] && hook_com[vcs]="hg" # "☿"
}

# hg: Show marker when the working directory is not on a branch head
# This may indicate that running `hg up` will do something
# NOTE: the branchheads.cache file is not updated with every Mercurial
# operation, so it will sometimes give false positives. Think of this more as a
# hint that you might not be on a branch head instead of the final word.
# 
# An example of a case where the report may be incorrect is immediately after
# a commit. An easy and relatively low cost solution is to make a post-commit
# hook that calls hg summary on the repository, updating the cache.
# For example, in your global hgrc, simply include something like:
#
# [hooks]
# post-commit = hg summary >/dev/null
# 
function +vi-hg-branchhead() {
    local branchheadsfile i_tiphash i_branchname
    local -a branchheads
    local branchheadsfile=${hook_com[base]}/.hg/branchheads.cache
    # Bail out if any mq patches are applied
    [[ -s ${hook_com[base]}/.hg/patches/status ]] && return 0
    if [[ -r ${branchheadsfile} ]] ; then
        while read -r i_tiphash i_branchname ; do
            branchheads+=( $i_tiphash )
        done < ${branchheadsfile}
        if [[ ! ${branchheads[(i)${user_data[hash]}]} -le ${#branchheads} ]] ; 
        then
            #hook_com[revision]=%U^%u$hook_com[revision]
            hook_com[revision]=^$hook_com[revision]
        fi
    fi
}

function +vi-check-untracked() {
    if [[ ${hook_com[vcs_orig]} == git ]]; then
        [[ ! -z $(git ls-files --other --exclude-standard ${hook_com[base]} 2> /dev/null) ]] &&\
        hook_com[unstaged]="${FMT_UNTRACKED}${hook_com[unstaged]}"
    elif [[ ${hook_com[vcs_orig]} == hg ]]; then
        [[ ! -z $(hg st -un 2> /dev/null) ]] &&\
        hook_com[unstaged]="${FMT_UNTRACKED}${hook_com[unstaged]}"
    fi

    # add padding ... this should be a separate function but failed if it was
    # indeed it should probably be just some conditional formatting in the vcs
    # format string, but I couldn't get that working
    #
    # I could also just break out the vcs_info into mutliple parts and pad
    # later
    if [[ -n ${hook_com[unstaged]} ]]; then
        hook_com[unstaged]=" ${hook_com[unstaged]}"
    elif [[ -n ${hook_com[staged]} ]]; then
        hook_com[staged]=" ${hook_com[staged]}"
    fi
}

function +vi-add-padding() {
    if [[ -n ${hook_com[misc]} ]]; then
        hook_com[misc]=" (${hook_com[misc]})"
    fi
}


# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name --abbrev-ref 2>/dev/null)}

    if [[ -n ${remote} ]] ; then
        # for git prior to 1.7
        # ahead=$(git rev-list origin/${hook_com[branch]}..HEAD | wc -l)
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        (( $ahead )) && gitstatus+=( "${green}+${${ahead}// /}${gray}" )

        # for git prior to 1.7
        # behind=$(git rev-list HEAD..origin/${hook_com[branch]} | wc -l)
        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
        (( $behind )) && gitstatus+=( "${red}-${${behind}// /}${gray}" )

        hook_com[branch]="${hook_com[branch]} ${vcsbase}[${remote}${(j:/:)gitstatus}${vcsbase}]"
    fi
}

# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes

    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l)
        hook_com[misc]+="stash:${${stashes}// /}"
    fi
}

get_length () {
    #local string_len
    string_len=${(S)${1}//\%\{*\%\}}    # search-and-replace color escapes
    string_len=${#${(%)string_len}}     # expand escapes and count the chars
    result string_len
}

# Assemble the prompt string
function setprompt () {
    local x i filler i_width i_pad newline newlinefix
    local infouser infopath infovcs infoline infoleader promptleader promptline promptchar
    local padding
    
    padding=" "

    # stopped jobs in info leader, otherwise dashes
    infoleader="%(100j.${base2}%j .%(10j.${base1}%j] .%(1j.${base00}[%j] .--- )))${reset}"

    # SHLVL (L) aware prompt leader
    # TODO: use $(pgrep -f urxvtd) instead of uname
    case $(uname) in
        Linux)
            promptleader="%(7L.${yellow}%L${reset}>> .%(6L.>>> .%(5L.->> .--> )))"
        ;;
        Darwin)
            promptleader="%(4L.${yellow}%L${reset}>> .%(3L.>>> .%(2L.->> .--> )))"
        ;; 
    esac
    newline=$'\n'
    newline_conditional=$'%1(l.\n.)'

    # username & host
    infouser="%(!.${yellow}.${base00})%n${reset}"
    if [[ -n $SSH_CLIENT ]]; then
        infouser+="${blue}@%m${reset}"
    else
        infouser+="@%m"
    fi

    # vcs
    [[ -n ${vcs_info_msg_0_} ]]\
        && infovcs="${gray}${vcs_info_msg_0_}${padding}${reset}"\
        || infovcs=""

    # TODO: if path plus leader and username alone (no vcs) is greater than
    # termwidth, truncate path to fit and place vcs string (which should almost
    # always be shorter than termwidth except) on the next line, creating
    # a three line prompt
    #
    # actually, on second thought, i should be checking the last path component
    # width and making that the minimum visible element (along with an
    # ellipsis) and if we can't fit that then making it multiline. or I could
    # do a root git name+that with an ellipsis

    # compile working infoline to check max path length
    infoline=$infoleader$infouser$infovcs
    i_width=${(S)infoline//\%\{*\%\}} # search-and-replace color escapes
    i_width=${#${(%)i_width}} # expand all escapes and count the chars
    # check for overflow
    local TERMWIDTH MAXPATHWIDTH
    (( TERMWIDTH = ${COLUMNS} ))
    # -1 for padding to right of the actual path string
    (( MAXPATHWIDTH = $TERMWIDTH - $i_width -1 )) 

    # current dir; show in yellow if not writable
    [[ -w $PWD ]] && infopath+=${blue} || infopath+=${red}
    infopath+="%$MAXPATHWIDTH<…<%~%<<${reset}${padding}"

    # compile temporary infoline to check width for filler
    infoline=$infoline$infopath
    
    i_width=${(S)infoline//\%\{*\%\}} # search-and-replace color escapes
    i_width=${#${(%)i_width}} # expand all escapes and count the chars
    
    (( REMAININGWIDTH = $TERMWIDTH - $i_width ))
    filler="${gray}${(l:$(( $REMAININGWIDTH ))::-:: :)}"
    filler+="${reset}"

    #infoline=( "${infoline} ${filler}" )
    infoline=$infoleader$infopath$infovcs$filler$infouser

    # prompt, changes color based on error status
    # OLD:leader is replaced by number of jobs if present
    # OLD:promptline="%(1j.${gray}[%j] ${reset}.${promptleader})"
    promptchar="%(0?.%(!.${yellow}.${base00}).${colorwarn})%#${reset} "

    # final prompt string
    #PROMPT=$infoline$newline$promptline
    PROMPT=$infoline$newline_conditional$promptleader$promptchar
}

add-zsh-hook precmd ejas_precmd
ejas_precmd () {
    vcs_info
    setprompt
}

