# IMPORTS
import numpy as np

# FUNÇÃO QUE CALCULA O IoU
def bb_intersection_over_union(boxA, boxB):
    # DETERMINA AS COORDENADAS (x, y) DA INTERSECÇÃO ENTRE AS BBOX
    xA = max(boxA[0], boxB[0])
    yA = max(boxA[1], boxB[1])
    xB = min(boxA[2], boxB[2])
    yB = min(boxA[3], boxB[3])

    # CÁLCULA A ÁREA DE INTERSECÇÃO
    interArea = (xB - xA + 1) * (yB - yA + 1)

    # CÁLCULA A ÁREA DE CADA BBOX
    boxAArea = (boxA[2] - boxA[0] + 1) * (boxA[3] - boxA[1] + 1)
    boxBArea = (boxB[2] - boxB[0] + 1) * (boxB[3] - boxB[1] + 1)

    # CALCULA A INTERSECÇÃO SOBRE A UNIÃO DIVIDINDO A ÁREA DE INTERSECÇÃO PELA
    # DIFERENÇA DA SOMA DAS ÁREAS DE CADA BBOX COM A ÁREA DE INTERSECÇÃO
    iou = interArea / float(boxAArea + boxBArea - interArea)

    return iou, boxAArea, boxBArea

# FUNÇÃO QUE ORGANIZA A SAÍDA DO MODELO, SALVANDO UMA MATRIZ COM A SAÍDA E UM VETOR COM AS CONFIANÇAS
def read_model_out(saida):
  i = 0
  j = 0
  predictions = [[0 for _ in range(6)] for _ in range(4032)]
  confidences = [0 for _ in range(4032)]

  for k in range(len(saida)):
    predictions[i][j] = saida[k]
    if(j == 4):
      confidences[i] = saida[k]

    j = j + 1
    if(j == 6):
      i = i + 1
      j = 0

  return predictions, confidences

# FUNÇÃO QUE SELECIONA SOMENTE AS MELHORES PREDIÇÕES
def select_best_predictions(predictions, confidences):
  confidencesThreshold = 0.6
  aux = 0
  best_pred = []

  for i in range(4032):
      if(confidences[i] >= confidencesThreshold):
        best_pred.append(predictions[i])
        aux = aux + 1

  best_pred = np.array(best_pred)
  return best_pred

# FUNÇÃO PARA AJUSTAR AS MELHORES PREDIÇÕES PARA XI, XF, YI, YF

def output_adjust(best_pred):

  best_pred_adj = [[0 for _ in range(6)] for _ in range(len(best_pred))]

  for i in range(len(best_pred)):
    xC = round(256 * best_pred[i][0])
    xW = round(256 * best_pred[i][2])
    yC = round(256 * best_pred[i][1])
    yH = round(256 * best_pred[i][3])

    xi = xC - round(xW/2)
    xf = xC + round(xW/2)
    yi = yC - round(yH/2)
    yf = yC + round(yH/2)
    if(xi <= 0):
      xi = 0
    if(xf >= 255):
      xf = 255
    if(yi <= 0):
      yi = 0
    if(yf >= 255):
      yf = 255

    best_pred_adj[i] = [xi, yi, xf, yf, best_pred[i][4], round(best_pred[i][5])]

  return best_pred_adj

def main(saida):
    predictions, confidences = read_model_out(saida)
    best_pred = select_best_predictions(predictions, confidences)
    best_pred_adj = output_adjust(best_pred)

    detected_objects = []
    best_pred_adj_list = list(best_pred_adj)
    aux = 0

    while( len(best_pred_adj_list) > 0 ):
      aux = aux + 1

      actual_obj = best_pred_adj_list.pop(0)
      detected_objects.append(actual_obj)
      bboxA = [ actual_obj[0], actual_obj[1], actual_obj[2], actual_obj[3] ]

      idx = []
      for i in range(len(best_pred_adj_list)):
        analyzed_obj = best_pred_adj_list[i]
        bboxB = [ analyzed_obj[0], analyzed_obj[1], analyzed_obj[2], analyzed_obj[3] ]

        iou, bbAreaA, bbAreaB = bb_intersection_over_union(bboxA, bboxB)
        if(iou > 0.5):
          if(bbAreaB > bbAreaA):
            if(analyzed_obj[0] < 240 and analyzed_obj[2] < 240 and analyzed_obj[1] < 80 and analyzed_obj[3] < 80):
                rmv = detected_objects.pop(aux-1)
                detected_objects.append(analyzed_obj)

          idx.append(i)

      aux3 = 0
      for j in range(len(idx)):
        rmv = best_pred_adj_list.pop(idx[j]-aux3)
        aux3 = aux3 + 1

    xi_array = [0 for _ in range(len(detected_objects))]
    for i in range(len(detected_objects)):
      xi_array[i] = detected_objects[i][0]

    # REARRANJA BBOXES PARA OS PRIMEIROS CARACTERES SEREM OS MAIS À ESQUERDA
    sort_idx = np.argsort(xi_array)
    sorted_detected_objects = []
    for i in range(len(detected_objects)):
      sorted_detected_objects.append(detected_objects[sort_idx[i]])

    bounding_boxes_chars = []
    for i in range(len(sorted_detected_objects)):
      xi = sorted_detected_objects[i][0]+0
      xf = sorted_detected_objects[i][2]+1
      yi = sorted_detected_objects[i][1]
      yf = sorted_detected_objects[i][3]
      bounding_boxes_chars.append([xi, xf, yi, yf])

    bounding_boxes_chars = np.array(bounding_boxes_chars)
    return bounding_boxes_chars