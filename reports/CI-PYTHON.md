# Python CI verification

[GitHub Actions run 43727124040](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/actions/runs/43727124040) completed successfully for source commit `a1ee1d8428e1cc2159795078a977942442bffeac` on 2026-11-15.

| Hosted environment | Python | Unit methods | Result |
|---|---|---:|---|
| windows-latest | 3.10 | 61 | PASS |
| windows-latest | 3.13 | 61 | PASS |
| ubuntu-latest | 3.10 | 61 | PASS |
| ubuntu-latest | 3.13 | 61 | PASS |

Each job installed the package, ran the unittest suite, built the wheel and source distribution, ran `gtb version`, and uploaded a nonempty artifact. Four nonexpired artifact bundles were observed through GitHub's API. Job step outcomes, the exact log summaries and artifact metadata are preserved in `ci-python-current.json`, `ci-python-test-counts.txt` and `ci-python-artifacts.json`.

These are 61 distinct tests repeated across four environments, not 244 distinct tests. This supplies hosted Ubuntu execution/build evidence in addition to local Windows testing. It does not claim macOS execution or authenticated/live network testing on the hosted runners. The local ten-check installed-wheel acceptance and real GitHub write/readback have separate receipts. CI artifact bundle digests are not the local release-wheel digest and are not presented as such.

The preceding run [43726999339](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/actions/runs/43726999339) also completed successfully for commit `c3e1b40aa71cd1a9227b287155f7c1978a2de459`; the latest commit-specific result above is the primary evidence. Documentation commits after this review require their own run status if represented as CI-verified heads.
