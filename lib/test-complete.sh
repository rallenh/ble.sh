# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-complete
ble-import lib/core-test

ble/test/start-section 'ble/complete' 21

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

# #D2427 #682 曖昧補完に於けるパス名の成分毎の一致文字数
(
  ## @fn _count comp_type compv value
  ##   @var[out] ret
  function _count {
    local comp_type=$1 comps_fixed= COMPV=$2
    local filter_type=substr
    case :$comp_type: in
    (*:a:*) filter_type=hsubseq ;;
    (*:A:*) filter_type=subseq ;;
    esac
    ble/complete/candidates/count-match-chars "$filter_type" "$3"
  }

  # 単一成分 (従来通り文字列全体で数える)
  ble/test '_count :m: bc abc'                     ret=2
  ble/test '_count :m: sub/ab sub/abc'             ret=6

  # 複数成分 (#682 成分を跨ぐ一致は文字列全体では数えられない)
  ble/test '_count :m: sub/bc sub/abc'             ret=6
  ble/test '_count :m: sub/deep/yz sub/deep/xyz'   ret=11
  ble/test '_count :m: /tmp/bc /tmp/abc'           ret=7

  # 末尾の成分は部分一致で良い (残りは後から挿入される)
  ble/test '_count :m: sub/bcq sub/abc'            ret=6

  # 途中の成分が一致しない時は成分の対応付けが誤っているので数えない
  ble/test '_count :m: xx/bc sub/abc'              ret=0

  # hsubseq は文字列全体でも / を跨いで数えられる
  ble/test '_count :a: sub/ac sub/abc'             ret=6
)

# #D2427 #682 存在しない部分文字列を含むパスの補完
(
  ## @fn _common ambiguous_flag comps
  ##   @var[out] ret
  function _common {
    local comp_type=:sync:$1: comps_flags=v comps_fixed=
    local COMPS=$2 COMPV=$2 COMP1=0 COMP2=${#2}
    local comp_filter_type=substr comp_filter_pattern=
    case $1 in
    (a) comp_filter_type=hsubseq ;;
    (A) comp_filter_type=subseq ;;
    esac
    local flag_source_filter=1
    local cand_count cand_limit_reached
    local -a cand_cand cand_word cand_pack
    ble/complete/candidates/clear
    ble/complete/source:file
    ret=
    ble/complete/candidates/determine-common-prefix
  }

  ble/test/chdir || exit
  command mkdir -p sub/deep
  command touch sub/abc1 sub/abc2 sub/abc3
  command touch sub/deep/xyz1 sub/deep/xyz2

  # Note: #682 以前は共通部分と入力が連結されて "sub/abcsub/bc" になっていた。
  ble/test '_common m sub/bc'        ret='sub/abc'
  ble/test '_common m sub/deep/yz'   ret='sub/deep/xyz'
  ble/test '_common A sub/deep/xz'   ret='sub/deep/xyz'

  # 先頭一致する時の振る舞いは変わらない
  ble/test '_common m sub/ab'        ret='sub/abc'
  ble/test '_common m sub/deep/xyz'  ret='sub/deep/xyz'

  ble/test/rmdir
)

# #D2427 共通部分が入力の何処にも一致しない時は補完挿入を行わない
(
  ## @fn _common ambiguous_flag comps
  ##   @var[out] ret
  function _common {
    local comp_type=:sync:$1: comps_flags=v comps_fixed=
    local COMPS=$2 COMPV=$2 COMP1=0 COMP2=${#2}
    local comp_filter_type=substr comp_filter_pattern=
    local flag_source_filter=1
    local cand_count cand_limit_reached
    local -a cand_cand cand_word cand_pack
    ble/complete/candidates/clear
    ble/complete/source:file
    ret=
    ble/complete/candidates/determine-common-prefix
  }

  ble/test/chdir || exit
  command mkdir -p qsubq qsubq2
  command touch qsubq/abc qsubq2/xbc

  # Note: 候補の共通部分 "qsubq" は入力 "sub/bc" の何処にも一致しない。以前は共
  #   通部分と入力を連結して "qsubqsub/bc" を挿入していた。
  ble/test '_common m sub/bc' ret='sub/bc'

  ble/test/rmdir
)

ble/test/end-section

ble/test/start-section 'ble/complete/progcomp' 13

# A tilde after a wordbreak is not expanded unless the word is an assignment
(
  ## @fn _compvar [-p POINT] words...
  ##   Construct COMP_WORDS for the command line "words..." with the cursor at
  ##   POINT in the last word (default: end of line).
  ##   @var[out] ret
  ##     The last element of COMP_WORDS.
  function _compvar {
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
)

ble/test/end-section
