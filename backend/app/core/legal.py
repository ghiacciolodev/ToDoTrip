"""Which version of the privacy policy a user agreed to.

A date rather than a number, because it is the date printed at the top of
mobile/assets/legal/privacy-policy.md and the two have to be checked against
each other by eye. Bump it when the document changes in a way that matters;
leave it alone for a typo.

Storing the version and not just a boolean is the difference between "they
ticked a box once" and being able to say what they were shown. Article 7(1)
asks a controller to demonstrate consent, and a bare flag demonstrates nothing
after the text has been edited.
"""

PRIVACY_POLICY_VERSION = "2026-08-19"
