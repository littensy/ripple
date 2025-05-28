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

type NonStrict<T extends Animatable> = T extends number ? number : T;

export function useSpring<T extends Animatable>(
	initialValue: T,
	initialOptions?: SpringOptions<T>,
): LuaTuple<[getter: () => T, spring: Spring<NonStrict<T>>]>;

export function useTween<T extends Animatable>(
	initialValue: T,
	initialOptions?: TweenOptions<T>,
): LuaTuple<[getter: () => T, tween: Tween<NonStrict<T>>]>;

export function useMotion<T extends Animatable>(
	initialValue: T,
	initialOptions?: MotionOptions<T>,
): LuaTuple<[getter: () => T, motion: Motion<NonStrict<T>>]>;

export function useSequence<T extends Animatable>(
	initialValue: T,
	keypoints: SequenceKeypoint<T>[],
	startImmediately?: boolean,
): LuaTuple<[getter: () => T, sequence: Sequence<NonStrict<T>>]>;
