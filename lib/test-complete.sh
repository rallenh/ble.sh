# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-complete
ble-import lib/core-test

ble/test/start-section 'ble/complete' 20

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

# https://github.com/akinomyoga/ble.sh/issues/682
(
  ## @fn _count compv value
  function _count {
    local comp_type=:m: COMPV=$1
    ble/complete/candidates/determine-common-prefix/.count-match-chars substr "$2"
  }
  ble/test '_count bc abc'                    ret=2
  ble/test '_count sub/bc sub/abc'            ret=6
  ble/test '_count sub/bc sub/abcs'           ret=6
  ble/test '_count sub/deep/yz sub/deep/xyz'  ret=11
  ble/test '_count s/b/c sub/ba'              ret=3
  ble/test '_count sub/bcq sub/abc'           ret=6
  ble/test '_count xx/bc sub/abc'             ret=0

  ## @fn _common comp_type files... -- compv
  function _common {
    local comp_type=:sync:$1: filter=substr; shift
    case $comp_type in (*:A:*) filter=subseq ;; (*:a:*) filter=hsubseq ;; esac
    ble/test/chdir || return 1
    command mkdir -p sub/deep
    while [[ $1 != -- ]]; do command touch "$1"; shift; done
    local COMPS=$2 COMPV=$2 COMP1=0 COMP2=${#2} comps_flags=v comps_fixed=
    local comp_filter_type=$filter comp_filter_pattern= flag_source_filter=1
    local cand_count cand_limit_reached
    local -a cand_cand cand_word cand_pack
    ble/complete/candidates/clear
    ble/complete/source:file
    ret=
    ble/complete/candidates/determine-common-prefix
    ble/test/rmdir
  }
  # Before the fix, these became "sub/abcsub/bc" etc.
  ble/test '_common m sub/abc1 sub/abc2 -- sub/bc'                ret='sub/abc'
  ble/test '_common m sub/abcs1 sub/abcs2 -- sub/bc'              ret='sub/abcs'
  ble/test '_common m sub/deep/xyz1 sub/deep/xyz2 -- sub/deep/yz' ret='sub/deep/xyz'
  ble/test '_common m sub/qabc sub/qxbc -- sub/bc'                ret='sub/qbc'
  # Unchanged
  ble/test '_common m sub/abc1 sub/abc2 -- sub/ab'                ret='sub/abc'
  ble/test '_common A xabyc xcbyc -- bc'                          ret='xbc'
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

ble/test/start-section 'ble/complete/action:progcomp' 4

(
  ## @fn _complete DATA CAND
  ##   Calls action:progcomp/complete for a candidate that completes the word
  ##   "host:/h/Doc", and returns the final insert string and suffix in ret.
  function _complete {
    local DATA=$1 CAND=$2 insert=$2 COMPS='host:/h/Doc' COMPV='host:/h/Doc'
    local comps_flags=v comps_fixed= COMP_PREFIX= insert_flags= suffix=
    ble/complete/action:progcomp/complete
    ret=$insert/$suffix/
  }

  # "ble/syntax-raw": inserted as is (scp generates remote files escaped for
  # the local and remote shells)
  ble/test '_complete :ble/syntax-raw:nospace: "host:/h/Docs\\\\\\ A/"' ret='host:/h/Docs\\\ A///'
  ble/test '_complete :ble/syntax-raw: "host:/h/Docs\\\\\\ A"' ret='host:/h/Docs\\\ A/ /'

  # without "ble/syntax-raw": requoted as before
  ble/test '_complete :nospace: "host:/h/Docs\\\\\\ A/"' ret="'host:/h/Docs\\ A/'//"
  ble/test '_complete : "host:/h/Docs\\ A\\ B"' ret="'host:/h/Docs A B'/ /"
)

ble/test/end-section
