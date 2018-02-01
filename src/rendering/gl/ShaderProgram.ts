import {vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;

  unifView:   WebGLUniformLocation;
  unifScreen: WebGLUniformLocation;
  unifUp:     WebGLUniformLocation;
  unifEye: WebGLUniformLocation;
  unifTime:   WebGLUniformLocation;
  

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    // Raymarcher only draws a quad in screen space! No other attributes
    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");

    // TODO: add other attributes here
    this.unifView   = gl.getUniformLocation(this.prog, "u_View");
    this.unifScreen = gl.getUniformLocation(this.prog, "u_Screen");
    this.unifUp     = gl.getUniformLocation(this.prog, "u_Up");
    this.unifEye = gl.getUniformLocation(this.prog, "u_Eye");
    this.unifTime   = gl.getUniformLocation(this.prog, "u_Time");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  // TODO: add functions to modify uniforms

  setSize(width: number, height: number) {
    this.use();
    if (this.unifScreen != -1) {
      gl.uniform2f(this.unifScreen, width, height);
    }
  }

  setTime(count: number) {
    this.use();
    if (this.unifScreen != - 1) {
      gl.uniform1f(this.unifTime, count);
    }
  }

  setCamera(up: vec3, eye: vec3) {
    this.use();
    if (this.unifUp != - 1) {
      gl.uniform3fv(this.unifUp, up);
    }
    if (this.unifEye != -1) {
      gl.uniform3fv(this.unifEye, eye);
    }
  }

  setViewMatrix(view: mat4) {
    this.use();
    if (this.unifView != - 1) {
      let inverseView : mat4 = mat4.create();
      mat4.invert(inverseView, view);
      gl.uniformMatrix4fv(this.unifView, false, inverseView);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);

  }
};

export default ShaderProgram;
