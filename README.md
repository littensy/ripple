# 🎨 Ripple

**Ripple** is a simple, lightweight, and easy-to-use Roblox library for creating simple transitions and animations. It is inspired by [react-spring](https://react-spring.dev) and aims to provide an imperative API for general use.

## Installation

Ripple is available on [NPM](https://www.npmjs.com/package/@rbxts/ripple) and can be installed with the following commands:

```bash
npm install @rbxts/ripple
yarn add @rbxts/ripple
pnpm add @rbxts/ripple
```

```toml
# Wally
Ripple = "littensy/ripple@version"
```

## Reference

### Supported types

The following data types are supported for animation:

| Data type                  | [Converted type](./packages/ripple/src/utils/intermediate.luau) |
| -------------------------- | --------------------------------------------------------------- |
| number                     | `[number]`                                                      |
| vector                     | `[vector]`                                                      |
| Vector2                    | `[vector]`                                                      |
| Vector3                    | `[vector]`                                                      |
| Color3                     | `[vector]` (Oklab)                                              |
| UDim                       | `[vector]`                                                      |
| UDim2                      | `[vector, number]`                                              |
| CFrame                     | `[vector, vector, vector, vector]`                              |
| Rect                       | `[vector, number]`                                              |
| Map<any, number \| vector> | `Map<any, number \| vector>`                                    |

---

### `createSpring(initialValue, options)`

`createSpring` creates a spring object starting at the given value.

```lua
local spring = createSpring(0, {
	tension = 170,
	friction = 26,
	start = true,
})

spring:setGoal(1)
spring:onChange(print) --> number, deltaTime
```

[Try the react-spring visualizer →](https://react-spring-visualizer.com)

#### Parameters

- `initialValue`: The value that the spring should start with.
- **optional** `options`: The physical properties of the spring.

#### Options

| Option           | Type      | Description                                                                                    |
| ---------------- | --------- | ---------------------------------------------------------------------------------------------- |
| tension[^1]      | `number`  | Influences the number of bounces in the animation. Defaults to `170`.                          |
| friction[^1]     | `number`  | Influences the level of spring in the animation. Defaults to `26`.                             |
| mass[^1]         | `number`  | Influences the speed of the spring and height of the bounce. Defaults to `1`.                  |
| frequency[^2]    | `number`  | How quickly the spring responds to changes.                                                    |
| dampingRatio[^2] | `number`  | Dictates how the spring slows down.                                                            |
| precision        | `number`  | The distance to the goal before the spring is considered idle. Defaults to `0.001`.            |
| restVelocity     | `number`  | The smallest velocity before the spring is considered idle. Derived from precision by default. |
| position         | `T`       | Set the position of the spring.                                                                |
| velocity         | `T`       | Set the velocity of the spring.                                                                |
| impulse          | `T`       | Add to the velocity of the spring.                                                             |
| start            | `boolean` | Connect to Heartbeat while animating. Defaults to `false`.                                     |

[^1]: Tension, friction, and mass are not compatible with frequency or damping ratio.

[^2]: Frequency and damping ratio are not compatible with tension, friction, or mass.

#### Returns

`createSpring` returns a spring object.

---

### `createTween(initialValue, options)`

`createTween` creates a tween object starting at the given value.

```lua
local tween = createTween(0, {
	easing = "quadOut",
	duration = 1,
	start = true,
})

tween:setGoal(1)
tween:onChange(print) --> number, deltaTime
```

#### Parameters

- `initialValue`: The value that the spring should start with.
- **optional** `options`: The properties of the tween.

#### Options

| Option   | Type      | Description                                                    |
| -------- | --------- | -------------------------------------------------------------- |
| easing   | `Easing`  | The [easing function](#easing-functions) to use for animation. |
| duration | `number`  | Duration of one repetition of the tween, in seconds.           |
| repeats  | `number`  | Number of times the tween repeats.                             |
| reverses | `boolean` | Reverse directions when repeating.                             |
| position | `T`       | Continue the rest of the tween from this position.             |
| start    | `boolean` | Connect to Heartbeat while animating. Defaults to `false`.     |

#### Easing functions

|               |                |                  |
| ------------- | -------------- | ---------------- |
| `"linear"`    | `"instant"`    | `"smoothstep"`   |
| `"sineIn"`    | `"sineOut"`    | `"sineInOut"`    |
| `"backIn"`    | `"backOut"`    | `"backInOut"`    |
| `"quadIn"`    | `"quadOut"`    | `"quadInOut"`    |
| `"quartIn"`   | `"quartOut"`   | `"quartInOut"`   |
| `"quintIn"`   | `"quintOut"`   | `"quintInOut"`   |
| `"bounceIn"`  | `"bounceOut"`  | `"bounceInOut"`  |
| `"elasticIn"` | `"elasticOut"` | `"elasticInOut"` |
| `"expoIn"`    | `"expoOut"`    | `"expoInOut"`    |
| `"circIn"`    | `"circOut"`    | `"circInOut"`    |
| `"cubicIn"`   | `"cubicOut"`   | `"cubicInOut"`   |

[See examples of easing functions →](https://easings.net)

#### Returns

`createTween` returns a tween object.

---

### `createMotion(initialValue, options)`

`createMotion` creates an animation that switches between a spring and a tween.

```lua
local motion = createMotion(0, {
	spring = { tension = 170, friction = 26 },
	tween = { easing = "quadOut", duration = 1 },
	start = true,
})

motion:onChange(print) --> number, deltaTime
motion:tween(1)
task.wait(1)
motion:spring(0)
```

> [!WARNING]
>
> This creates both a spring and a tween object, which can be wasteful if your animation uses only one or the other.
>
> Use [`createSpring`](#createspringinitialvalue-options) or [`createTween`](#createtweeninitialvalue-options) if you do not need to switch animation types.

#### Parameters

- `initialValue`: The value that the spring and tween should start with.
- **optional** `options`: The properties of the spring or tween.

#### Options

| Option | Type               | Description                                                  |
| ------ | ------------------ | ------------------------------------------------------------ |
| spring | `SpringOptions<T>` | The [spring options](#options) to use for spring animations. |
| tween  | `TweenOptions<T>`  | The [tween options](#options-1) to use for tween animations. |
| start  | `boolean`          | Connect to Heartbeat while animating. Defaults to `false`.   |

#### Returns

`createMotion` returns a motion object that controls a spring and a tween.

---

<p align="center">
Ripple is licensed under the <a href="LICENSE.md">MIT License</a>.
</p>

<div align="center">

[![GitHub License](https://img.shields.io/github/license/littensy/ripple?)](LICENSE.md)

</div>
