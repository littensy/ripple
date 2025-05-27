local Ripple = require(script.Parent.Parent.ripple.src)

export type Animatable = Ripple.Animatable
export type Easing = Ripple.Easing
export type Spring<T> = Ripple.Spring<T>
export type SpringConfig<T> = Ripple.SpringConfig<T>
export type Tween<T> = Ripple.Tween<T>
export type TweenConfig<T> = Ripple.TweenConfig<T>
export type Motion<T> = Ripple.Motion<T>
export type MotionConfig<T> = Ripple.MotionConfig<T>
export type Sequence<T> = Ripple.Sequence<T>
export type SequenceKeypoint<T> = Ripple.SequenceKeypoint<T>

return Ripple
