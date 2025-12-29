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
        const { email, password, fullName, phoneNumber, region, role, appType } = await req.json();

        // Validate required fields
        if (!email || !password || !fullName || !phoneNumber || !role) {
            throw new Error('Missing required fields: email, password, fullName, phoneNumber, role');
        }

        // Validate role
        if (!['admin', 'super_admin'].includes(role)) {
            throw new Error('Role must be either admin or super_admin');
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
            throw new Error('Only super admins can create admin accounts');
        }

        // Create new auth user using Admin API
        const createUserResponse = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${serviceRoleKey}`,
                'apikey': serviceRoleKey,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email,
                password,
                email_confirm: true,
                user_metadata: {
                    full_name: fullName,
                    phone_number: phoneNumber,
                    role
                }
            })
        });

        if (!createUserResponse.ok) {
            const errorText = await createUserResponse.text();
            throw new Error(`Failed to create user: ${errorText}`);
        }

        const newUser = await createUserResponse.json();
        const newUserId = newUser.id;

        // Create profile entry
        const profileInsertResponse = await fetch(`${supabaseUrl}/rest/v1/profiles`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${serviceRoleKey}`,
                'apikey': serviceRoleKey,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            },
            body: JSON.stringify({
                id: newUserId,
                email,
                full_name: fullName,
                phone_number: phoneNumber,
                region: region || null,
                role,
                app_type: appType || role, // Use role as app_type if not specified
                created_by: requesterId,
                is_active: true,
                is_verified: true
            })
        });

        if (!profileInsertResponse.ok) {
            const errorText = await profileInsertResponse.text();
            // Rollback: Delete the auth user if profile creation fails
            await fetch(`${supabaseUrl}/auth/v1/admin/users/${newUserId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });
            throw new Error(`Failed to create profile: ${errorText}`);
        }

        const profileData_1 = await profileInsertResponse.json();

        return new Response(JSON.stringify({
            data: {
                message: 'Admin account created successfully',
                user: {
                    id: newUserId,
                    email,
                    role
                },
                credentials: {
                    email,
                    password,
                    note: 'Share these credentials securely with the admin'
                },
                profile: profileData_1[0]
            }
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Create admin account error:', error);

        const errorResponse = {
            error: {
                code: 'CREATE_ADMIN_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});
