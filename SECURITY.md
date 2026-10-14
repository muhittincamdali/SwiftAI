# Security policy

## Supported versions

Security fixes are made for the latest release. Version 1.0.0 is a different, unmaintained code
base and does not receive fixes.

## What counts as a vulnerability

SwiftAI runs inside apps and often reads data the app does not control: CSV files, downloaded
model files, values typed by a user. Please report privately any input that makes SwiftAI:

- crash (a trap, an out-of-range index, an integer overflow) instead of throwing `SwiftAIError`,
- loop for a very long time or allocate memory out of proportion to the input,
- accept a damaged or crafted model file and then predict with invalid values,
- return NaN or infinity from a function that documents that it throws instead.

Wrong but finite results from valid input are bugs, not vulnerabilities; open a regular issue for
those.

## Reporting a vulnerability

Please report vulnerabilities privately, not in a public issue, pull request or discussion.

1. **Preferred:** open the repository's **Security** tab and choose
   **Report a vulnerability** ([how private reporting works](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately)).
2. **Or** email [muhittincamdali@gmail.com](mailto:muhittincamdali@gmail.com) with
   "Security" in the subject.

Include the SwiftAI version (tag or commit), the input that triggers the problem (a small CSV or
JSON file is ideal) and what happens.

## What happens next

- You get a reply within 7 days confirming that the report arrived.
- The issue is confirmed, fixed with a regression test, and released together with a GitHub
  security advisory on a disclosure date agreed with you.
- You are credited in the advisory unless you prefer not to be.
