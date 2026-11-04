---
title: daisyUI themes and semantic color names
date: 2026-11-04
input_shape: concept
subject: daisyUI 5 on Tailwind CSS 4
---

# daisyUI themes and semantic color names

## What it is

daisyUI is a Tailwind CSS plugin that adds component classes (`btn`, `card`, `input`, `alert`, ...) and a
theme system. A theme is a set of CSS variables. The components and the color utilities read the colors by
role, not by value:

- `base-100`, `base-200`, `base-300`: page and surface backgrounds; `base-content`: text on them
- `primary`, `secondary`, `accent`, `neutral`: brand roles
- `info`, `success`, `warning`, `error`: states
- each role has a `-content` pair, the color of text placed on it (`bg-primary text-primary-content`)

A theme also sets the shape: border radius for selectors (checkbox, toggle, badge), fields (button, input,
select) and boxes (card, modal, alert), the base size of components, border width, and two effects, `depth`
(shadow and slight relief) and `noise` (grain). Its `color-scheme` tells the browser whether native controls
and scrollbars should be light or dark.

## Why here

Views say what a color is for (`btn-primary`, `bg-base-200`), and the active theme decides what it looks like.
Ermida starts with the stock `light` and `dark` themes. A custom Ermida theme can replace them later without
editing any view, because no view names a concrete color.

## Example

`app/javascript/entrypoints/application.css`:

```css
@import "tailwindcss" source("../..");

@plugin "daisyui" {
  themes: light --default, dark --prefersdark;
}
```

`light` applies by default and `dark` when the operating system prefers dark mode, with no JavaScript. A page
can force one with `data-theme="dark"` on `<html>`. A custom theme is declared with
`@plugin "daisyui/theme" { name: "ermida"; default: true; --color-primary: ...; }` and listed the same way.

## When not to use it

- For a one-off color with no role (a chart series, a brand logo color), use a plain Tailwind color or a
  custom property instead of bending a theme role to fit.
- Do not hardcode colors such as `bg-white` or `text-gray-900` on themed surfaces: they ignore the theme and
  break in dark mode.
