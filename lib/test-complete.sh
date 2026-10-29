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
