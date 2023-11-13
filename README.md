# 🎨 Ripple

**Ripple** is a simple, lightweight, and easy-to-use Roblox library for creating simple transitions and animations. It is inspired by [roact-spring](https://github.com/chriscerie/roact-spring) and is primarily intended to be a general-use alternative to [Flipper](https://github.com/Reselim/Flipper) for [Roblox-TS](https://roblox-ts.com).

You may use Ripple with or without Roact. Currently, there is no package for using Ripple with Roact.

## 📦 Installation

Ripple is available on [NPM](https://www.npmjs.com/package/@rbxts/ripple) and can be installed with the following commands:

```bash
npm install @rbxts/ripple
yarn add @rbxts/ripple
pnpm add @rbxts/ripple
```

## 📚 Documentation
### ⚡ Quick Start

Call `createMotion` to create a motion object.

Use the `linear` method to move your value. You can also use methods like `spring` or `tween`.

Use the `onStep` binding to apply your value.

```typescript
import { createMotion, Motion, MotionGoal } from "@rbxts/ripple";

const motion = createMotion(0)
motion.onStep(print);

motion.linear(1)
```

### ⚛️ Usage with React

You can use this hook to start using ripple in your React UI.

```typescript
import { createMotion, Motion, MotionGoal } from "@rbxts/ripple";
import { Binding, useBinding, useEffect, useMemo } from "@rbxts/roact";

export function useMotion(goal: number): LuaTuple<[Binding<number>, Motion<number>]>;

export function useMotion<T extends MotionGoal>(goal: T): LuaTuple<[Binding<T>, Motion<T>]>;

export function useMotion<T extends MotionGoal>(goal: T) {
	const motion = useMemo(() => {
		return createMotion(goal, { start: true });
	}, []);

	const [binding, setValue] = useBinding(motion.get());

	useEffect(() => {
		const disconnect = motion.onStep(setValue);

		return () => {
			disconnect();
			motion.destroy();
		};
	}, []);

	return $tuple(binding, motion);
}
```

To see the hook in action, visit the `src/client` folder in the [example repository](https://github.com/littensy/rbxts-react-example) to see it in action.

### 📝 License

Ripple is licensed under the MIT License.