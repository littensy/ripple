type Key = string | number | symbol;

export type AnimatablePrimitive = number | vector | Vector3;

export type AnimatableType = AnimatablePrimitive | Vector2 | CFrame | Color3 | UDim | UDim2 | Rect;

export type Animatable = AnimatableType | Record<Key, AnimatablePrimitive>;

export type PartialGoal<T extends Animatable> = T extends AnimatableType ? T : Partial<T>;

export type Easing =
	| "linear"
	| "smoothstep"
	| "instant"
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
	| "cubicInOut";

export interface SpringOptions<T extends Animatable = any> {
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

export interface Spring<T extends Animatable = any> {
	getPosition(): T;
	getVelocity(): T;
	getGoal(): T;

	setPosition(value: PartialGoal<T>): void;
	setVelocity(value: PartialGoal<T>): void;
	setGoal(value: PartialGoal<T>, options?: SpringOptions<T>): void;

	onChange(callback: (value: T, deltaTime: number) => void): () => void;
	onComplete(callback: (value: T) => void): () => void;

	step(deltaTime: number): T;
	impulse(amount: PartialGoal<T>): void;
	halt(): void;
	idle(): boolean;
	configure(options: SpringOptions<T>): void;

	start(): void;
	stop(): void;
	destroy(): void;
}

export interface TweenOptions<T extends Animatable = any> {
	start?: boolean;
	easing?: Easing;
	duration?: number;
	repeats?: number;
	reverses?: boolean;
	position?: T;
}

export interface Tween<T extends Animatable = any> {
	getPosition(): T;
	getFrom(): T;
	getGoal(): T;

	setPosition(value: PartialGoal<T>): void;
	setFrom(value: PartialGoal<T>): void;
	setGoal(value: PartialGoal<T>, options?: TweenOptions<T>): void;

	onChange(callback: (value: T, deltaTime: number) => void): () => void;
	onComplete(callback: (value: T) => void): () => void;

	step(deltaTime: number): T;
	idle(): boolean;
	configure(options: TweenOptions<T>): void;

	start(): void;
	stop(): void;
	destroy(): void;
}

export interface MotionOptions<T extends Animatable = any> {
	start?: boolean;
	spring?: SpringOptions<T>;
	tween?: TweenOptions<T>;
}

export interface Motion<T extends Animatable = any> {
	getPosition(): T;
	getVelocity(): T;
	getGoal(): T;

	setPosition(value: PartialGoal<T>): void;
	setVelocity(value: PartialGoal<T>): void;
	setGoal(value: PartialGoal<T>, options?: MotionOptions<T>): void;

	onChange(callback: (value: T, deltaTime: number) => void): () => void;
	onComplete(callback: (value: T) => void): () => void;

	step(deltaTime: number): T;
	spring(goal: PartialGoal<T>, options?: SpringOptions<T>): void;
	tween(goal: PartialGoal<T>, options?: TweenOptions<T>): void;
	idle(): boolean;
	configure(options: MotionOptions<T>): void;

	start(): void;
	stop(): void;
	destroy(): void;
}

export function createSpring<T extends Animatable>(initialValue: T, options?: SpringOptions<T>): Spring<T>;

export function createSpring(initialValue: number, options?: SpringOptions<number>): Spring<number>;

export function createTween<T extends Animatable>(initialValue: T, options?: TweenOptions<T>): Tween<T>;

export function createTween(initialValue: number, options?: TweenOptions<number>): Tween<number>;

export function createMotion<T extends Animatable>(initialValue: T, options?: MotionOptions<T>): Motion<T>;

export function createMotion(initialValue: number, options?: MotionOptions<number>): Motion<number>;

export const config: {
	default: SpringOptions;
	gentle: SpringOptions;
	wobbly: SpringOptions;
	stiff: SpringOptions;
	slow: SpringOptions;
	molasses: SpringOptions;
};

export const easing: {
	[K in Easing]: (x: number) => number;
};
