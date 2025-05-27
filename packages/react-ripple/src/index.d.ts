import type { Binding } from "@rbxts/react";
import type {
	Animatable,
	Motion,
	MotionConfig,
	Sequence,
	SequenceKeypoint,
	Spring,
	SpringConfig,
	Tween,
	TweenConfig,
} from "@rbxts/ripple";

export * from "@rbxts/ripple";

export function useSpring<T extends Animatable>(
	initialValue: T,
	initialConfig?: SpringConfig<T>,
): LuaTuple<[binding: Binding<T>, spring: Spring<T>]>;

export function useTween<T extends Animatable>(
	initialValue: T,
	initialConfig?: TweenConfig<T>,
): LuaTuple<[binding: Binding<T>, tween: Tween<T>]>;

export function useMotion<T extends Animatable>(
	initialValue: T,
	initialConfig?: MotionConfig<T>,
): LuaTuple<[binding: Binding<T>, motion: Motion<T>]>;

export function useSequence<T extends Animatable>(
	initialValue: T,
	keypoints: SequenceKeypoint<T>[],
	startImmediately?: boolean,
): LuaTuple<[binding: Binding<T>, sequence: Sequence<T>]>;
