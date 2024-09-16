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

```toml
# Wally
Ripple = "littensy/ripple@0.9.1"
```

## 📚 Documentation

To see Ripple in action, check out the [example repository](https://github.com/littensy/rbxts-react-example).

### ⚡ Quick Start

Call `createMotion` to create an animation.

Use the `spring`, `linear`, `immediate`, and `tween` methods to set the goal of your animation.

```typescript
import { Motion, MotionGoal, config, createMotion } from "@rbxts/ripple";

const motion = createMotion(Vector3.zero, { start: true });

motion.spring(Vector3.one, config.spring.stiff);

motion.onStep((value, deltaTime) => {
	print(value, deltaTime);
});

print(motion.get());
```

You can also apply different goal types to specific properties using the `to` method:

```typescript
const motion = createMotion({ x: 0, y: 0 });

motion.to({
	x: spring(100, config.spring.stiff),
	y: linear(100),
});
```

### ⚛️ Usage with React

#### `useMotion(initialValue)`

Creates a memoized Motion object set to the given initial value.

Returns a binding that updates with the Motion, along with the Motion object.

```typescript
function MyComponent() {
	const [binding, motion] = useMotion(0);
	// ...
}
```

```typescript
export function useMotion(initialValue: number): LuaTuple<[Binding<number>, Motion]>;

export function useMotion<T extends MotionGoal>(initialValue: T): LuaTuple<[Binding<T>, Motion<T>]>;

export function useMotion<T extends MotionGoal>(initialValue: T) {
	const motion = useMemo(() => {
		return createMotion(initialValue);
	}, []);

	const [binding, setValue] = useBinding(initialValue);

	useEventListener(RunService.Heartbeat, (delta) => {
		const value = motion.step(delta);

		if (value !== binding.getValue()) {
			setValue(value);
		}
	});

	return $tuple(binding, motion);
}
```

#### `useSpring(value, springConfig?)`

Applies spring animations to the given value, and updates the goal with the latest value on every re-render.

Returns a binding that updates with the Motion.

```typescript
function MyComponent({ someValue }: Props) {
	const binding = useSpring(someValue);
	// ...
}
```

```typescript
export function useSpring(goal: number | Binding<number>, options?: SpringOptions): Binding<number>;

export function useSpring<T extends MotionGoal>(goal: T | Binding<T>, options?: SpringOptions): Binding<T>;

export function useSpring(goal: MotionGoal | Binding<MotionGoal>, options?: SpringOptions) {
	const [binding, motion] = useMotion(getBindingValue(goal));
	const previousValue = useRef(getBindingValue(goal));

	useEventListener(RunService.Heartbeat, () => {
		const currentValue = getBindingValue(goal);

		if (currentValue !== previousValue.current) {
			previousValue.current = currentValue;
			motion.spring(currentValue, options);
		}
	});

	return binding;
}
```

### 📝 License

Ripple is licensed under the MIT License.
