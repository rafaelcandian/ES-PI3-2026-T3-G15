// Autor: 
// RA: 
// Descrição: Middleware factory para validação de campos obrigatórios no corpo da requisição.

import { Request, Response, NextFunction } from 'express';

export const validateBody = (requiredFields: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const missingFields: string[] = [];

    for (const field of requiredFields) {
      const value = req.body[field];
      if (value === null || value === undefined || value === '') {
        missingFields.push(field);
      }
    }

    if (missingFields.length > 0) {
      return res.status(400).json({
        error: 'Campos obrigatórios ausentes',
        campos: missingFields
      });
    }

    return next();
  };
};
