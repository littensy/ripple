import type { Animatable, Motion, MotionOptions, Spring, SpringOptions, Tween, TweenOptions } from "@rbxts/ripple";

export * from "@rbxts/ripple";

type NonStrict<T extends Animatable> = T extends number ? number : T;

export function useSpring<T extends Animatable>(
	initialValue: T,
	initialOptions?: SpringOptions<T>,
): LuaTuple<[getter: () => NonStrict<T>, spring: Spring<NonStrict<T>>]>;

export function useTween<T extends Animatable>(
	initialValue: T,
	initialOptions?: TweenOptions<T>,
): LuaTuple<[getter: () => NonStrict<T>, tween: Tween<NonStrict<T>>]>;

export function useMotion<T extends Animatable>(
	initialValue: T,
	initialOptions?: MotionOptions<T>,
): LuaTuple<[getter: () => NonStrict<T>, motion: Motion<NonStrict<T>>]>;
