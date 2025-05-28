local Ripple = require(script.Parent.Parent.ripple.src)

export type Animatable = Ripple.Animatable
export type Easing = Ripple.Easing
export type Motion<T = any> = Ripple.Motion<T>
export type MotionOptions<T = any> = Ripple.MotionOptions<T>
export type Sequence<T = any> = Ripple.Sequence<T>
export type SequenceKeypoint<T = any> = Ripple.SequenceKeypoint<T>
export type Spring<T = any> = Ripple.Spring<T>
export type SpringOptions<T = any> = Ripple.SpringOptions<T>
export type Tween<T = any> = Ripple.Tween<T>
export type TweenOptions<T = any> = Ripple.TweenOptions<T>

return Ripple
