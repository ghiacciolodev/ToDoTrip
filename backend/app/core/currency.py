"""The currency codes a trip is allowed to be kept in.

A trip's currency is a label, not a conversion: the app says so plainly, and
nothing recomputes amounts when it changes. That is exactly why the code has to
be real. An unchecked three-letter field accepts "ABC" and "XXX", and the
result is a column of numbers with a meaningless symbol in front of them that
no later feature can repair.
"""

# ISO 4217 alphabetic codes, as published for 2024, restricted to currencies
# that actually circulate.
#
# Deliberately left out:
#   - the precious metals (XAU, XAG, XPT, XPD) and the test code XTS,
#   - XXX, "no currency",
#   - the fund codes (BOV, CHE, CHW, CLF, COU, MXV, USN, UYI, UYW) and the
#     supranational units (XDR, XBA-XBD, XSU), which are accounting
#     instruments nobody splits a dinner in.
# The territorial francs and the Caribbean dollar (XAF, XOF, XPF, XCD) stay:
# those are money people carry.
# Kept as text grouped by initial rather than as a list literal: 156 quoted
# strings on one line cannot be checked against the standard by eye, and one
# per line would bury the file.
_CODES = """
    AED AFN ALL AMD ANG AOA ARS AUD AWG AZN
    BAM BBD BDT BGN BHD BIF BMD BND BOB BRL BSD BTN BWP BYN BZD
    CAD CDF CHF CLP CNY COP CRC CUP CVE CZK
    DJF DKK DOP DZD EGP ERN ETB EUR
    FJD FKP GBP GEL GHS GIP GMD GNF GTQ GYD
    HKD HNL HTG HUF IDR ILS INR IQD IRR ISK
    JMD JOD JPY KES KGS KHR KMF KPW KRW KWD KYD KZT
    LAK LBP LKR LRD LSL LYD
    MAD MDL MGA MKD MMK MNT MOP MRU MUR MVR MWK MXN MYR MZN
    NAD NGN NIO NOK NPR NZD OMR
    PAB PEN PGK PHP PKR PLN PYG QAR RON RSD RUB RWF
    SAR SBD SCR SDG SEK SGD SHP SLE SOS SRD SSP STN SVC SYP SZL
    THB TJS TMT TND TOP TRY TTD TWD TZS
    UAH UGX USD UYU UZS VED VES VND VUV WST
    XAF XCD XOF XPF YER ZAR ZMW ZWG
"""

ISO_4217 = frozenset(_CODES.split())


def normalise(code: str) -> str:
    """Upper-case the code and check it exists.

    Case is normalised rather than rejected: "eur" is a client being sloppy, not
    a user being wrong, and storing both "eur" and "EUR" would split the same
    currency in two.
    """
    upper = code.strip().upper()
    if upper not in ISO_4217:
        raise ValueError(f"{code!r} is not a circulating ISO 4217 currency code")
    return upper
