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

export interface VideSpring<T extends Animatable> extends Spring<T> {
	(): T;
	source: () => T;
}

export interface VideTween<T extends Animatable> extends Tween<T> {
	(): T;
	source: () => T;
}

export interface VideMotion<T extends Animatable> extends Motion<T> {
	(): T;
	source: () => T;
}

export interface VideSequence<T extends Animatable> extends Sequence<T> {
	(): T;
	source: () => T;
}

export function useSpring<T extends Animatable>(initialValue: T, initialConfig?: SpringConfig<T>): VideSpring<T>;

export function useTween<T extends Animatable>(initialValue: T, initialConfig?: TweenConfig<T>): VideTween<T>;

export function useMotion<T extends Animatable>(initialValue: T, initialConfig?: MotionConfig<T>): VideMotion<T>;

export function useSequence<T extends Animatable>(
	initialValue: T,
	keypoints: SequenceKeypoint<T>[],
	startImmediately?: boolean,
): VideSequence<T>;
