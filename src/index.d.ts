type Cleanup = () => void;

type DeepPartial<T> = T extends object
	? {
			[K in keyof T]?: DeepPartial<T[K]>;
	  }
	: T;

export = Ripple;
export as namespace Ripple;

declare namespace Ripple {
	const config: {
		readonly spring: {
			readonly default: SpringOptions;
			readonly gentle: SpringOptions;
			readonly wobbly: SpringOptions;
			readonly stiff: SpringOptions;
			readonly slow: SpringOptions;
			readonly molasses: SpringOptions;
		};
		readonly linear: {
			readonly default: LinearOptions;
		};
		readonly tween: {
			readonly default: TweenOptions;
		};
	};

	interface Heartbeat {
		Connect(callback: (deltaTime: number) => void): Disconnectable;
	}

	interface Disconnectable {
		Disconnect(): void;
	}

	interface MotionOptions {
		readonly heartbeat?: Heartbeat;
		readonly start?: boolean;
	}

	function createMotion(initialValue: number, options?: MotionOptions): Motion<number>;

	function createMotion<T extends MotionGoal>(initialValue: T, options?: MotionOptions): Motion<T>;

	// Motion solvers

	function immediate<T extends MotionGoal>(goal: T): MotionSolver<T>;

	interface LinearOptions {
		readonly speed?: number;
	}

	function linear<T extends MotionGoal>(goal: T, options?: LinearOptions): MotionSolver<T>;

	interface SpringOptions {
		readonly damping?: number;
		readonly frequency?: number;
		readonly mass?: number;
		readonly tension?: number;
		readonly friction?: number;
		readonly position?: number;
		readonly velocity?: number;
		readonly impulse?: number;
	}

	function spring<T extends MotionGoal>(goal: T, options?: SpringOptions): MotionSolver<T>;

	interface TweenOptions {
		readonly time?: number;
		readonly style?: Enum.EasingStyle;
		readonly direction?: Enum.EasingDirection;
		readonly repeatCount?: number;
		readonly reverses?: boolean;
		readonly delayTime?: number;
	}

	function tween<T extends MotionGoal>(goal: T, options?: TweenOptions): MotionSolver<T>;
}

declare namespace Ripple {
	interface Motion<T extends MotionGoal = number> {
		readonly state: MapGoalTo<T, MotionState>;
		start(): Cleanup;
		stop(): void;
		get(): T;
		getVelocity(): T;
		set(value: PartialMotionGoal<T>): void;
		impulse(velocity: PartialMotionGoal<T>): void;
		to(solver: MotionSolver<T> | MapSolvers<PartialMotionGoal<T>>): void;
		step(deltaTime: number): T;
		isComplete(): boolean;
		onComplete(callback: (value: T) => void): Cleanup;
		onStep(callback: (value: T, deltaTime: number) => void): Cleanup;
		patch(source: DeepPartial<MapGoalTo<T, MotionState>>): void;
		destroy(): void;
	}

	type MapSolvers<T extends PartialMotionGoal> = T extends number[]
		? {
				[K in keyof T]?: T[K] extends undefined | infer U extends number ? MotionSolver<U> : T[K];
		  }
		: T extends { [key: string | number]: number }
		? {
				[K in keyof T]?: T[K] extends number | undefined ? MotionSolver<T[K]> : T[K];
		  }
		: MotionSolver<T>;

	type MapGoalTo<T extends MotionGoal, U> = T extends number[]
		? {
				[K in keyof T]: T[K] extends number ? U : T[K];
		  }
		: T extends { [key: string | number]: number }
		? {
				[K in keyof T]: T[K] extends number ? U : T[K];
		  }
		: T extends number
		? U
		: U[]; // internal intermediate values for datatypes

	type MotionGoal =
		| { [key: string | number]: number }
		| number[]
		| number
		| UDim2
		| UDim
		| Vector2
		| Vector3
		| Color3
		| CFrame;

	type PartialMotionGoal<T extends MotionGoal = MotionGoal> = T extends number[] | { [key: string | number]: number }
		? Partial<T>
		: T;

	interface MotionState {
		value: number;
		complete: boolean;
		velocity?: number;
		destructor?: Cleanup;
	}

	type MotionSolver<T extends PartialMotionGoal> = ((key: string, state: MotionState, deltaTime: number) => void) & {
		/**
		 * @deprecated Reserved for internal use
		 */
		__type: T;
	};
}
