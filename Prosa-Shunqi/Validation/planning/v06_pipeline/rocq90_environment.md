# Active Rocq 9.0 validation environment

The current formal validation baseline is stock Rocq 9.0.0 with OCaml 4.14.2,
MathComp 2.4.0, and `coq-mathcomp-zify` 1.5.0+2.0+8.16. Lean is 4.33.1 and
Mathlib is pinned to `0df444a360eaa60ab8c11dca51a86af692955474`.

Run `Validation/scripts/setup_rocq90_environment.sh` to reuse or materialize
the repository-local switch, then `Validation/scripts/check_rocq90_environment.sh`
to fail closed on every required package version. These scripts do not change
the global default OPAM switch.

The importer is pinned to upstream commit
`b8291b9dae4f5ed780112e95eea484e435199b46` and applies the single
`rocq90-importer.patch`. Normal universe and elimination checking remain
enabled and `with_unsafe_univs f () = f ()`. No unsafe universe patch,
experimental `Acc` mapping, or alternate baseline is supported.
