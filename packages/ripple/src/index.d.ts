export = Ripple;

type Key = string | number | symbol;

declare namespace Ripple {
	type Animatable =
		| number
		| vector
		| Vector2
		| Vector3
		| CFrame
		| Color3
		| UDim
		| UDim2
		| Rect
		| Record<Key, number | vector | Vector3>;

	type Easing =
		| "linear"
		| "sineIn"
		| "sineOut"
		| "sineInOut"
		| "backIn"
		| "backOut"
		| "backInOut"
		| "quadIn"
		| "quadOut"
		| "quadInOut"
		| "quartIn"
		| "quartOut"
		| "quartInOut"
		| "quintIn"
		| "quintOut"
		| "quintInOut"
		| "bounceIn"
		| "bounceOut"
		| "bounceInOut"
		| "elasticIn"
		| "elasticOut"
		| "elasticInOut"
		| "expoIn"
		| "expoOut"
		| "expoInOut"
		| "circIn"
		| "circOut"
		| "circInOut"
		| "cubicIn"
		| "cubicOut"
		| "cubicInOut"
		| "smoothstep"
		| "instant";

	interface SpringConfig<T extends Animatable> {
		start?: boolean;
		tension?: number;
		friction?: number;
		mass?: number;
		dampingRatio?: number;
		frequency?: number;
		precision?: number;
		restVelocity?: number;
		position?: T;
		velocity?: T;
		impulse?: T;
	}

	interface Spring<T extends Animatable> {
		position: T;
		velocity: T;
		goal: T;

		onChange: (callback: (value: T, deltaTime: number) => void) => () => void;
		onComplete: (callback: (value: T) => void) => () => void;

		step: (deltaTime: number) => T;
		to: (goal: T, config?: SpringConfig<T>) => void;
		impulse: (amount: T) => void;
		halt: () => void;
		idle: () => boolean;
		configure: (config: SpringConfig<T>) => void;

		start: () => void;
		stop: () => void;
		destroy: () => void;
	}

	interface TweenConfig<T extends Animatable> {
		start?: boolean;
		easing?: Easing;
		duration?: number;
		repeats?: number;
		reverses?: boolean;
		position?: T;
	}

	interface Tween<T extends Animatable> {
		position: T;
		from: T;
		goal: T;

		onChange: (callback: (value: T, deltaTime: number) => void) => () => void;
		onComplete: (callback: (value: T) => void) => () => void;

		step: (deltaTime: number) => T;
		to: (goal: T, config?: TweenConfig<T>) => void;
		idle: () => boolean;
		configure: (config: TweenConfig<T>) => void;

		start: () => void;
		stop: () => void;
		destroy: () => void;
	}

	interface MotionConfig<T extends Animatable> {
		start?: boolean;
		spring?: SpringConfig<T>;
		tween?: TweenConfig<T>;
	}

	interface Motion<T extends Animatable> {
		position: T;
		velocity: T;
		goal: T;

		onChange: (callback: (value: T, deltaTime: number) => void) => () => void;
		onComplete: (callback: (value: T) => void) => () => void;

		step: (deltaTime: number) => T;
		spring: (goal: T, config?: SpringConfig<T>) => void;
		tween: (goal: T, config?: TweenConfig<T>) => void;
		idle: () => boolean;
		configure: (config: MotionConfig<T>) => void;

		start: () => void;
		stop: () => void;
		destroy: () => void;
	}

	interface SequenceKeypoint<T extends Animatable> {
		time: number;
		goal: T;
		spring?: SpringConfig<T>;
		tween?: TweenConfig<T>;
	}

	interface Sequence<T extends Animatable> {
		time: number;
		position: T;
		velocity: T;
		readonly goal: T;

		onChange: (callback: (value: T, deltaTime: number) => void) => () => void;
		onComplete: (callback: (value: T) => void) => () => void;

		step: (deltaTime: number) => T;
		idle: () => boolean;

		loop: () => void;
		start: () => void;
		stop: () => void;
		destroy: () => void;
	}

	function createSpring<T extends Animatable>(initialValue: T, config?: SpringConfig<T>): Spring<T>;

	function createTween<T extends Animatable>(initialValue: T, config?: TweenConfig<T>): Tween<T>;

	function createMotion<T extends Animatable>(initialValue: T, config?: MotionConfig<T>): Motion<T>;

	function createSequence<T extends Animatable>(initialValue: T, keypoints: SequenceKeypoint<T>[]): Sequence<T>;

	const config: {
		readonly default: Readonly<SpringConfig<any>>;
		readonly gentle: Readonly<SpringConfig<any>>;
		readonly wobbly: Readonly<SpringConfig<any>>;
		readonly stiff: Readonly<SpringConfig<any>>;
		readonly slow: Readonly<SpringConfig<any>>;
		readonly molasses: Readonly<SpringConfig<any>>;
	};

	const easing: {
		readonly [K in Easing]: (x: number) => number;
	};

	namespace heartbeat {
		function id(): number;
		function step(dt: number): void;
		function connect(id: number, callback: (dt: number) => void): void;
		function disconnect(id: number): void;
		function count(): number;
		function clear(): void;
	}
}
