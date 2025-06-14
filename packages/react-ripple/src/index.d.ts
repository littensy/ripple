import type { Binding } from "@rbxts/react";
import type { Animatable, Motion, MotionOptions, Spring, SpringOptions, Tween, TweenOptions } from "@rbxts/ripple";

export * from "@rbxts/ripple";

type NonStrict<T extends Animatable> = T extends number ? number : T;

export function useSpring<T extends Animatable>(
	initialValue: T,
	initialOptions?: SpringOptions<T>,
): LuaTuple<[binding: Binding<T>, spring: Spring<NonStrict<T>>]>;

export function useTween<T extends Animatable>(
	initialValue: T,
	initialOptions?: TweenOptions<T>,
): LuaTuple<[binding: Binding<T>, tween: Tween<NonStrict<T>>]>;

export function useMotion<T extends Animatable>(
	initialValue: T,
	initialOptions?: MotionOptions<T>,
): LuaTuple<[binding: Binding<T>, motion: Motion<NonStrict<T>>]>;
