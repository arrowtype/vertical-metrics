# Vertical Metrics

A repo for testing and documenting strategies for vertical metrics in fonts.

This repo is a work in (a very early state of) progress.

## Suggested vertical metrics *Still under review

For now, this is partially a hypothesis, based on slightly scattered testing. A key goal of this repo is to test and document more methodically, to determine where and how effective this approach is.

Apply to all styles within a family:

```py
# Set up your target line height
Line Height = UPM * 1.2 # your preferred ratio, probably 1.2 or greater

# hheaAscender must exceed /Agrave, or you should increase your Line Height
hheaAscender   = Cap Height + ((Line Height - Cap Height) / 2)
hheaDescender  = Cap Height - hheaAscender
hheaLineGap    = 0

# typoAscender controls framing in InDesign
typoAscender   = Cap Height
typoDescender  = hheaDescender
typoLineGap    = absolute value of hheaDescender # positive value

# important, or macOS app line height will be wrong in e.g. TextEdit
useTypoMetrics = False

# Sets default line heights and clipping heights in MS Word, etc
winAscent      = yMax in family
winDescent     = absolute value of yMin in family # positive value
```

## Goals and Scope

This repo seeks to test various vertical metrics parameters, in several important/representative apps, to determine a strategy for vertical metrics.

Such a strategy should ideally...
- Be as consistent as reasonable possible, between different platforms and apps
- Be intuitive to use and to read, for each major platform and app
- Be simple enough to describe and adapt to achieve type design goals

The repo will also seek to provide documentation behind new checks contributed to [Font Bakery](https://github.com/fonttools/fontbakery) and [Fontspector](https://github.com/fonttools/fontspector/).

This will be based mostly on Latin script and other scripts that are primarily set horizontally, but the documented behavior of metrics can likely help inform any OpenType font, for almost any script.

## What are vertical metrics?

“Vertical metrics” are values recorded in OpenType fonts which text-setting software use to determine the 

1. The offset applied to the first line of text within its space.
2. (Often) the default distance between lines of text.
3. (Sometimes) the offset applied between the last line of text and the bottom of its space.

There are three systems for recording these values: `typo`, `hhea`, and `win` values.

- typoAscender
- typoDescender
- typoLineGap
- hheaAscender
- hheaDescender
- hheaLineGap
- winAscent
- winDescent
- useTypoMetrics (Bit 7 of OS/2 fsSelection)

## What does each of these metrics *really do?*

Based on testing, how can we describe the effects of each set of metrics?

### `hhea` metrics

Generally, these set the top and bottom of lines in:
- Chrome
- macOS apps like TextEdit, which use CoreText

Mac apps have a quirk: if the hheaAscender doesn’t exceed the /Agrave height, the system gives the font a significantly larger line height.

- [ ] Test: what happens in other web browsers?
- [ ] Test: is Chrome on Windows the same as Chrome on Mac, or not?

### `typo` metrics

Generally, these set the top and bottom of lines in Adobe InDesign.

- [ ] Test: what happens in other Adobe apps?

### `win` metrics

Generally, these set the top and bottom of each line in MS Word. This also sets where clipping occurs in glyphs.

- [ ] Test: what happens in other Windows apps?

### When `useTypoMetrics` is True

If `useTypoMetrics` is set to True, most apps follow the typo metrics. 

However, this causes a few issues:
1. Mac apps now check if the typoAscender exceeds the /Agrave height, and apply tall metrics if not.
2. MS Word will follow the typo metrics, including for its clipping boundaries – regardless of what win metrics are set.
3. Because of issues 1 and 2, typo metrics *have to* be set well above the cap height, which can be unintuitive for InDesign users.

## Tested Strategies

All tested strategies share some basic features:
- Vertical metrics are set the same for all styles of a family

### Google Fonts

See the [full recommendations](https://googlefonts.github.io/gf-guide/metrics.html) for details. They basically boil down to:

```py
typoAscender   = Must exceed /Abreveacute (or, at a minimum, above /Agrave)
typoDescender  = capHeight - typoAscender
typoLineGap    = 0

useTypoMetrics = True

# Must match typo metrics
hheaAscender   = typoAscender
hheaDescender  = typoDescender
hheaLineGap    = 0

winAscent      = yMax in family
winDescent     = absolute value of yMin in family # positive value

# The sum of the font’s vertical metric values (absolute) should be 20-30% greater than the font’s UPM
# This may need to be greater for scripts outside of Latin, Cyrillic, and Greek (e.g. Devanagari)
```

### Google Fonts Min

Similar to "Google Fonts" strategy, but:
- `typoAscender` (and `hheaAscender`) set equal to top of /Agrave, which is the minimum suggested by the Google Fonts Guide

### Google Fonts Min Alt

Similar to "Google Fonts Min" strategy, but:
- Typo metrics set similar to Target Line Height strategy, with `typoAscender` at cap height and `typoLineGap` set to make up difference to `hhea`

### Target Line Height

Similar to Google Fonts strategy, but:
- Starts with a target line height (and adjusts if it’s too small)
- Sets `hhea` metrics based on target line height
- Sets `typoAscender` specifically for InDesign, then uses `typoLineGap` to make up the difference to `hhea` line height
- Sets `useTypoMetrics` to False, to allow hhea and win metrics to function well in other apps

```py
# Set up your target line height
Line Height = UPM * 1.4

# hheaAscender must exceed /Agrave, or you should increase your Line Height
hheaAscender   = Cap Height + ((Line Height - Cap Height) / 2)
hheaDescender  = Cap Height - hheaAscender
hheaLineGap    = 0

# typoAscender controls framing in InDesign
typoAscender   = Cap Height
typoDescender  = hheaDescender
typoLineGap    = absolute value of hheaDescender # positive value

# important, or macOS app line height will be wrong in e.g. TextEdit
useTypoMetrics = False

# Sets default line heights and clipping heights in MS Word, etc
winAscent      = yMax in family
winDescent     = absolute value of yMin in family # positive value
```

### Target Line Height B

Like "Target Line Height", but with the following changes:
- Matches `win` values to `hhea`, to match line heights at the expense of some possible clipping

```py
# Sets default line heights and clipping heights in MS Word, etc
winAscent      = hheaAscender
winDescent     = absolute value of hheaDescender # positive value
```

### Adobe Fonts

- [ ] todo: add this test

### GlyphsApp

- [ ] todo: add this test


## Why not just use the Google Fonts strategy?

There are several metrics strategies, but one of the most common is [the “Google Fonts” strategy for vertical metrics](googlefonts.github.io/gf-guide/metrics.html). It is used for all (or almost all) fonts on Google Fonts, and these fonts have massive usage. It is also suggested by a collection of checks within [Font Bakery](https://github.com/fonttools/fontbakery) and [Fontspector](https://github.com/fonttools/fontspector/), which further reinforces its dominance.

However, there are a few pitfalls of the Google Fonts strategy.

- It is web-focused, and does not create intuitive results for Adobe apps such as InDesign.
  - It suggests setting the typoAscender to exceed the `Abreveacute`. In InDesign, this pushes the first line of text significantly downwards from the top of the text frame, which can make it challenging to align text. (This is solvable by diving into text frame options, but it would be preferable to not require users do this.)
- It makes certain promises which are not reproducible. 
  - In particular, it suggests that setting win metrics to exceed the min and max Y values of a family will prevent Microsoft Word from clipping shapes in the font. However, it also requires setting "Use Typo Metrics" to True, which causes MS Word to ... use Typo metrics ... at which point, clipping still *does* occur. (As of Microsoft Word in Windows 11)
- It is biased towards the needs of fonts within the context of web UI.
  - It suggests centering caps within the typo/hhea metrics, which is very helpful in web UI, but may not always work well for fonts with atypical sizing relationships. In particular, many script fonts have a very low x-Height (relative to Cap Height), and may also have very tall swashes.
- It doesn’t allow the designer to start with a *target* line height, and is instead just a series of glyphs to exceed. So, if a designer wants to satisfy the Google Fonts guidelines, but also make a default line height of 1.5x UPM, they have to understand a lot to get there.

## Test approach

1. Create a Glyphs source which...
   1. Uses individual Exports settings to vary vertical metrics for testing different approaches.
   2. Includes glyphs that contains vertical measurements, which will have alternates which are exported specific to different test exports. (See diagram below)
2. Build via FontMake
3. Test each export in multiple apps and platforms, with consistent screenshots, to document results.
   1. Chrome
      1. Safari?
      2. Firefox?
   2. Mac TextEdit (CoreText)
   3. Adobe InDesign
   4. Adobe Illustrator
   5. MS Word on Windows
   6. MS Word on Mac
   7. Android?
   8. iOS?
   9. Maybe create a submission process, if others wish to contribute their own screenshots?
4. Store those screenshots, with additional notes as needed, in this repo.

![Diagram of Vertical Metrics Test Glyph](docs/img/vm-test-glyph-diagram.png)

## Test Results

- [ ] come up with more standard way to scale screenshots?

### InDesign

![Test results in InDesign](docs/img/screenshot-mac-indesign-260308.png)

- [ ] will update with further tests

## App Quirks

- InDesign
  - Sets all fonts to a line height of 120%, by default. This can be adjusted in Justification settings (Shift+Option+Command+J) > Auto Leading 
  - Sets top of text based on typoAscender. This can be changed per text frame: right click on text frame, go to Text Frame Options (Command+B) > Baseline Options > First Baseline, and you can choose a different Offset basis.


## Setting Vertical Metrics in various font editors

- GlyphsApp
- RoboFont
- FontLab


## Note on CJK fonts

In the [OpenType specification for OS/2 typoAscender](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#stypoascender), it says:

> For CJK (Chinese, Japanese, and Korean) fonts that are intended to be used for vertical (as well as horizontal) layout, the required value for sTypoAscender is that which describes the top of the ideographic em-box.

This has not been tested (yet) in this repo, but it is probably sound advice.

## Build

First, you need Python installed. You can get it from python.org if you haven’t yet installed it.

Then, you can run the setup:

`make setup`

Finally, run the build:

`make build`


## Contributing

- [ ] add details on how contributions can be made (e.g. Pull Requests vs Issues)

## Credits

Many thanks to:
- [The Type Founders](https://typographer.com/), for supporting much of the time that has been put into this testing.
- [Google Fonts](https://fonts.google.com/), for informing this approach and documentation, as well as for their support of foundational tools used here.
- (More credits to be added!)
- ArrowType (Stephen Nixon) for the primary design, writing, and testing done for this repo


## Background Resources

- [OpenType Spec: OS/2 Table](https://learn.microsoft.com/en-us/typography/opentype/spec/os2)
- [OpenType Spec: hhea Table](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea)
- [OpenType Spec: Recommendations](https://learn.microsoft.com/en-us/typography/opentype/spec/recom#tad)
- [Google Fonts Guide: Vertical Metrics](https://googlefonts.github.io/gf-guide/metrics.html)
- [GlyphsApp article on Vertical Metrics](https://glyphsapp.com/learn/vertical-metrics)
