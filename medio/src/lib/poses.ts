// Poses do Médio. Cada pose é um conjunto de ângulos (em graus) por articulação,
// mais um deslocamento de quadril, deslocamento vertical do corpo e expressão facial.
//
// Convenção de ângulos:
//   - spineLean: positivo = corpo inclina pra direita do espectador
//   - headTilt: positivo = cabeça inclina pra direita
//   - leftShoulder / rightShoulder: 0 = braço pendurado pra baixo;
//       valores positivos abrem o braço pra fora (lado esquerdo do espectador para o
//       leftShoulder, lado direito para o rightShoulder com sinal negativo)
//   - leftElbow / rightElbow: dobra do cotovelo a partir do upperArm
//   - leftHip / rightHip: abertura da perna a partir da vertical
//   - hipShift: desloca o quadril horizontalmente (peso de um lado)
//   - bodyY: desloca o corpo inteiro verticalmente (subir/descer)

export type FaceMood =
  | 'neutral'
  | 'happy'
  | 'curious'
  | 'surprised'
  | 'thinking'
  | 'troubled'
  | 'realizing'
  | 'calm'
  | 'tiny';

export interface Pose {
  headTilt: number;
  spineLean: number;
  leftShoulder: number;
  leftElbow: number;
  rightShoulder: number;
  rightElbow: number;
  leftHip: number;
  leftKnee: number;
  rightHip: number;
  rightKnee: number;
  hipShift: number;
  bodyY: number;
  face: FaceMood;
}

export type PoseName =
  | 'neutral'
  | 'proud'
  | 'curious'
  | 'surprised'
  | 'thinking'
  | 'troubled'
  | 'realizing'
  | 'calm'
  | 'tiny';

export const POSES: Record<PoseName, Pose> = {
  neutral: {
    headTilt: 0, spineLean: 0,
    leftShoulder: 12, leftElbow: 15,
    rightShoulder: -12, rightElbow: -15,
    leftHip: 4, leftKnee: 0,
    rightHip: -4, rightKnee: 0,
    hipShift: 0, bodyY: 0, face: 'neutral',
  },
  proud: {
    headTilt: -3, spineLean: -2,
    leftShoulder: 18, leftElbow: 10,
    rightShoulder: -18, rightElbow: -10,
    leftHip: 5, leftKnee: 0,
    rightHip: -5, rightKnee: 0,
    hipShift: 0, bodyY: 0, face: 'happy',
  },
  curious: {
    headTilt: -8, spineLean: 2,
    leftShoulder: 20, leftElbow: 25,
    rightShoulder: -10, rightElbow: -30,
    leftHip: 6, leftKnee: 0,
    rightHip: -3, rightKnee: 0,
    hipShift: 3, bodyY: 0, face: 'curious',
  },
  surprised: {
    headTilt: 5, spineLean: -5,
    leftShoulder: -20, leftElbow: 40,
    rightShoulder: 20, rightElbow: -40,
    leftHip: 6, leftKnee: -5,
    rightHip: -6, rightKnee: -5,
    hipShift: 0, bodyY: 0, face: 'surprised',
  },
  thinking: {
    headTilt: -12, spineLean: 3,
    leftShoulder: 30, leftElbow: 60,
    rightShoulder: -130, rightElbow: -90,
    leftHip: 8, leftKnee: 0,
    rightHip: -2, rightKnee: -5,
    hipShift: 4, bodyY: 0, face: 'thinking',
  },
  troubled: {
    headTilt: 10, spineLean: 5,
    leftShoulder: 25, leftElbow: 40,
    rightShoulder: -25, rightElbow: -40,
    leftHip: 4, leftKnee: 0,
    rightHip: -4, rightKnee: 0,
    hipShift: 0, bodyY: 0, face: 'troubled',
  },
  realizing: {
    headTilt: -5, spineLean: -3,
    leftShoulder: -90, leftElbow: -30,
    rightShoulder: 90, rightElbow: 30,
    leftHip: 4, leftKnee: 0,
    rightHip: -4, rightKnee: 0,
    hipShift: 0, bodyY: -5, face: 'realizing',
  },
  calm: {
    headTilt: 0, spineLean: 0,
    leftShoulder: 25, leftElbow: 70,
    rightShoulder: -25, rightElbow: -70,
    leftHip: 3, leftKnee: 0,
    rightHip: -3, rightKnee: 0,
    hipShift: 0, bodyY: 0, face: 'calm',
  },
  tiny: {
    headTilt: 0, spineLean: 0,
    leftShoulder: 10, leftElbow: 10,
    rightShoulder: -10, rightElbow: -10,
    leftHip: 3, leftKnee: 0,
    rightHip: -3, rightKnee: 0,
    hipShift: 0, bodyY: 0, face: 'tiny',
  },
};

export const ALL_POSE_NAMES: PoseName[] = [
  'neutral',
  'proud',
  'curious',
  'surprised',
  'thinking',
  'troubled',
  'realizing',
  'calm',
  'tiny',
];

export const deg2rad = (d: number) => (d * Math.PI) / 180;
