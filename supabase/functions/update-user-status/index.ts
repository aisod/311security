Deno.serve(async (req) => {
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE, PATCH',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false'
    };

    if (req.method === 'OPTIONS') {
        return new Response(null, { status: 200, headers: corsHeaders });
    }

    try {
        // Get request body
        const { userId, isActive, role } = await req.json();

        // Validate required fields
        if (!userId) {
            throw new Error('Missing required field: userId');
        }

        if (isActive === undefined && !role) {
            throw new Error('Must provide at least one field to update: isActive or role');
        }

        // Validate role if provided
        if (role && !['user', 'admin', 'super_admin'].includes(role)) {
            throw new Error('Invalid role. Must be user, admin, or super_admin');
        }

        // Get environment variables
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // Get authorization token from request header
        const authHeader = req.headers.get('authorization');
        if (!authHeader) {
            throw new Error('No authorization header');
        }

        const token = authHeader.replace('Bearer ', '');

        // Verify requester is authenticated and get their ID
        const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'apikey': serviceRoleKey
            }
        });

        if (!userResponse.ok) {
            throw new Error('Invalid token or unauthorized');
        }

        const userData = await userResponse.json();
        const requesterId = userData.id;

        // Prevent users from modifying their own account
        if (requesterId === userId) {
            throw new Error('Cannot modify your own account status');
        }

        // Check if requester is a super admin
        const profileCheckResponse = await fetch(
            `${supabaseUrl}/rest/v1/profiles?id=eq.${requesterId}&select=role`,
            {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                }
            }
        );

        if (!profileCheckResponse.ok) {
            throw new Error('Failed to verify requester profile');
        }

        const profileData = await profileCheckResponse.json();
        
        if (!profileData || profileData.length === 0 || profileData[0].role !== 'super_admin') {
            throw new Error('Only super admins can update user accounts');
        }

        // Build update object
        const updateData = { updated_at: new Date().toISOString() };
        if (isActive !== undefined) {
            updateData.is_active = isActive;
        }
        if (role) {
            updateData.role = role;
        }

        // Update profile
        const updateResponse = await fetch(
            `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`,
            {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(updateData)
            }
        );

        if (!updateResponse.ok) {
            const errorText = await updateResponse.text();
            throw new Error(`Failed to update profile: ${errorText}`);
        }

        const updatedProfile = await updateResponse.json();

        if (!updatedProfile || updatedProfile.length === 0) {
            throw new Error('User not found');
        }

        return new Response(JSON.stringify({
            data: {
                message: 'User account updated successfully',
                profile: updatedProfile[0]
            }
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Update user status error:', error);

        const errorResponse = {
            error: {
                code: 'UPDATE_USER_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});
