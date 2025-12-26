import { Request, Response } from 'express';
import { Role, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('RoleController');

export class RoleController {
  
  static async getAllRoles(req: Request, res: Response) {
    try {
      const roles = await Role.find().sort({ role_id: 1 });
      res.json({ error: false, data: roles });
    } catch (error: any) {
      logger.error('Error fetching roles', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async createRole(req: Request, res: Response) {
    try {
      const { role_name, description } = req.body;

      if (!role_name) {
        return res.status(400).json({ error: true, message: 'Role Name is required' });
      }

      const existingRole = await Role.findOne({ role_name });
      if (existingRole) {
        return res.status(400).json({ error: true, message: 'Role Name already exists' });
      }

      // Auto-increment role_id
      const lastRole = await Role.findOne().sort({ role_id: -1 });
      const role_id = lastRole ? lastRole.role_id + 1 : 1;

      const role = await Role.create({
        role_id,
        role_name,
        description
      });

      res.status(201).json({ error: false, message: 'Role created successfully', data: role });
    } catch (error: any) {
      logger.error('CreateRole error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateRole(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { role_name, description } = req.body;

      const updateData: any = { updated_at: new Date() };
      if (role_name) updateData.role_name = role_name;
      if (description !== undefined) updateData.description = description;

      const role = await Role.findOneAndUpdate(
        { role_id: parseInt(id) },
        { $set: updateData },
        { new: true }
      );

      if (!role) return res.status(404).json({ error: true, message: 'Role not found' });

      res.json({ error: false, message: 'Role updated successfully', data: role });
    } catch (error: any) {
      logger.error('UpdateRole error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async deleteRole(req: Request, res: Response) {
    try {
      const { id } = req.params;
      
      // Prevent deleting core roles if needed, but for now we'll allow it or rely on the user to be careful.
      // Maybe check if any user is assigned to this role before deleting? 
      // That would require importing User model, which is fine since we are in admin-api.
      
      const role = await Role.findOneAndDelete({ role_id: parseInt(id) });
      
      if (!role) return res.status(404).json({ error: true, message: 'Role not found' });

      res.json({ error: false, message: 'Role deleted successfully' });
    } catch (error: any) {
      logger.error('DeleteRole error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
