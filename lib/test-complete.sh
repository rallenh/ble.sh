# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-complete
ble-import lib/core-test

ble/test/start-section 'ble/complete' 7

(
  ## @fn _collect
  ##   @arr[in] args ret
  ##   @var[out] ret
  function _collect {
    local text=${args[1]} p0=0 i out=
    for ((i=0;i<${#ret[@]};i++)); do
      ((p=ret[i]))
      if ((i%2==0)); then
        out=$out${text:p0:p-p0}'['
      else
        out=$out${text:p0:p-p0}']'
      fi
      p0=$p
    done
    ((p0<${#text})) && out=$out${text:p0}
    ret=$out
  }
  ble/test 'args=(akf Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[ak]e[f]ile'
  ble/test 'args=(akf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='Makefile'
  ble/test 'args=(Mkf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[M]a[k]e[f]ile'
  ble/test 'args=(Maf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[Ma]ke[f]ile'
  ble/test 'args=(Mak Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[Mak]efile'
  ble/test 'args=(ake Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[ake]file'
  ble/test 'args=(afe Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[a]ke[f]il[e]'
)

ble/test/end-section

ble/test/start-section 'ble/complete/progcomp' 17

# A tilde after a wordbreak is not expanded unless the word is an assignment
(
  ## @fn _compvar [-c] [-p POINT] words...
  ##   Construct COMP_WORDS for the command line "words..." with the cursor at
  ##   POINT in the last word (default: end of line).
  ##   @var[out] ret
  ##     The last element of COMP_WORDS, or "cur" when -c is specified.
  function _compvar {
    local get_cur=; [[ $1 == -c ]] && get_cur=1 && shift
    local point=; [[ $1 == -p ]] && point=$2 && shift 2
    local -a comp_words=("$@")
    local comp_cword=$((${#comp_words[@]}-1)) comp_line comp_point
    comp_line="${comp_words[*]}" comp_point=${#comp_line}
    [[ $point ]] && ((comp_point-=${#comp_words[comp_cword]}-point))
    local COMP_WORDBREAKS=$' \t\n"\'><=;|&(:'
    local COMP_WORDS COMP_CWORD COMP_LINE COMP_POINT COMP_TYPE COMP_KEY cmd cur prev progcomp_prefix
    local comp_type=:sync:
    ble/complete/progcomp/.compvar-initialize
    ret=${COMP_WORDS[${#COMP_WORDS[@]}-1]}
    [[ $get_cur ]] && ret=$cur
  }
  ble/test '_compvar scp "host:~/"' ret="'~/'"
  ble/test '_compvar scp "host:~/Docs/"' ret="'~/Docs/'"
  ble/test '_compvar scp "host:~"' ret="'~'"
  ble/test '_compvar cmd "--opt=~/"' ret="'~/'"
  ble/test '_compvar cmd "a:b:~/x"' ret="'~/x'"
  ble/test '_compvar scp "~/a:~/"' ret="'~/'"
  ble/test '_compvar -p 5 scp "host:~/Docs"' ret="'~/Docs'"
  ble/test '_compvar scp "host:/abs/"' ret='/abs/'

  # a tilde at the beginning of a word or in an assignment is expanded
  ble/test '_compvar scp "~/"' ret="$HOME/"
  ble/test '_compvar cmd "VAR=a:~/"' ret="$HOME/"
  ble/test '_compvar export "PATH=/x:~/"' ret="$HOME/"
  ble/test '_compvar cmd "a[1]+=x:~/"' ret="$HOME/"
  ble/test '_compvar -p 0 scp "~/Docs"' ret="$HOME/Docs"

  # cur should end at the cursor when the current subword is requoted
  ble/test '_compvar -c -p 7 scp "host:~/Docs"' ret='~/'
  ble/test '_compvar -c -p 7 scp "host:~nosuchuser/x"' ret='~n'
  ble/test '_compvar -c scp "host:~/Docs"' ret="'~/Docs'"
  ble/test '_compvar -c -p 6 cmd "a:b c/x"' ret='c/'
)

ble/test/end-section
