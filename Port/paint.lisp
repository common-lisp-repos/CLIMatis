(cl:in-package #:clim3-port)

(defgeneric new-port-paint-pixel (port r g b alpha))

(defgeneric new-port-paint-mask (port mask color))

(defgeneric new-port-paint-opaque (port color))

(defgeneric new-port-paint-translucent (port color opacity))

(defgeneric new-port-paint-text (port text text-style color))

(defgeneric new-port-paint-trapezoids (port trapezoids color))

(defun new-paint-pixel (r g b alpha)
  (new-port-paint-pixel *new-port* r g b alpha))

(defun new-paint-mask (mask color)
  (new-port-paint-mask *new-port* mask color))

(defun new-paint-opaque (color)
  (new-port-paint-opaque *new-port* color))

(defun new-paint-translucent (color opacity)
  (new-port-paint-translucent *new-port* color opacity))

(defun new-paint-text (text text-style color)
  (new-port-paint-text *new-port* text text-style color))

(defun new-paint-trapezoids (trapezoids color)
  (new-port-paint-trapezoids *new-port* trapezoids color))
