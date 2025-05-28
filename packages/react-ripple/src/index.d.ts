import type { Binding } from "@rbxts/react";
import type {
	Animatable,
	Motion,
	MotionOptions,
	Sequence,
	SequenceKeypoint,
	Spring,
	SpringOptions,
	Tween,
	TweenOptions,
} from "@rbxts/ripple";

export * from "@rbxts/ripple";

export function useSpring<T extends Animatable>(
	initialValue: T,
	initialOptions?: SpringOptions<T>,
): LuaTuple<[binding: Binding<T>, spring: Spring<T>]>;

export function useTween<T extends Animatable>(
	initialValue: T,
	initialOptions?: TweenOptions<T>,
): LuaTuple<[binding: Binding<T>, tween: Tween<T>]>;

export function useMotion<T extends Animatable>(
	initialValue: T,
	initialOptions?: MotionOptions<T>,
): LuaTuple<[binding: Binding<T>, motion: Motion<T>]>;

export function useSequence<T extends Animatable>(
	initialValue: T,
	keypoints: SequenceKeypoint<T>[],
	startImmediately?: boolean,
): LuaTuple<[binding: Binding<T>, sequence: Sequence<T>]>;
