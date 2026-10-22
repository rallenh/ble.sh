# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-complete
ble-import lib/core-test

ble/test/start-section 'ble/complete' 8

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

(
  function _issue682 {
    ble/test/chdir || return 1
    command mkdir -p tmp/ble-regression
    command touch tmp/ble-regression/abc{1..2}

    local base=$PWD/tmp/ble-regression
    local comp_type=:sync:m:
    local comps_flags=v
    local comps_fixed=('')
    local COMP1=0
    local COMPS=$base/bc
    local COMPV=$COMPS
    local COMP2=${#COMPS}
    local comp_filter_type=substr
    local comp_filter_pattern=

    local simple_flags simple_ibrace reconstructed
    if ble/syntax:bash/simple-word/reconstruct-incomplete-word "$COMPS"; then
      reconstructed=$ret
      ble/syntax:bash/simple-word/evaluate-path-spec "$reconstructed" '' noglob:fixlen="${simple_ibrace#*:}"
      local i s
      for ((i=0;i<${#spec[@]};i++)); do
        s=${spec[i]}
        [[ $s == "$reconstructed" ]] || comps_fixed+=("${#s}:${path[i]}")
      done
    fi

    local flag_source_filter=1
    ble/complete/candidates/clear
    ble/complete/source:file
    ret=
    ble/complete/candidates/determine-common-prefix
    ret=${ret#"$PWD/"}
    ble/test/rmdir
  }

  ble/test '_issue682' ret='tmp/ble-regression/abc'
)

ble/test/end-section
